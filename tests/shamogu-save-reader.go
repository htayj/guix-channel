//go:build ignore

// Read-only, stdlib-only decoder for Shamogu v1.5.0 saves. Compile this file
// explicitly: its mirrors intentionally do not import or execute game code.
// The wire schema is pinned to Shamogu commit fcd439d4 and gruid v0.27.0.
// Exported fields (including caches) are retained; unexported runtime/UI/RNG state is
// not present in the native gob stream and therefore cannot be reconstructed.
package main

import (
	"bytes"
	"compress/zlib"
	"encoding/gob"
	"encoding/json"
	"fmt"
	"io"
	"os"
	"reflect"
	"sort"
)

const (
	MapLevels = 9
	MapWidth = 80
	MapHeight = 21
	NStatuses = 19
	PlayerID = 8 // three spirit slots plus five comestible slots
	Version = "v1.5.0"
)

type Point struct { X, Y int }
type Range struct { Min, Max Point }

type Game struct {
	Entities []*Entity
	Map *Map
	PR, PRnoise *PathRange
	Dir, Prev Point
	Turn int
	StatusTurn [NStatuses]int
	CorruptionTurn int
	Logs *Logs
	Mods []bool
	ProcInfo *ProcInfo
	Stats *Stats
	Version string
	Wizard Wizard
}

type Entity struct {
	Name string
	Rune rune
	P, KnownP Point
	Seen, Noise bool
	Role any
}

type Actor struct {
	HP, MaxHP, Defense, Attack int
	FirePos Point
	KnownDead bool
	Statuses []int
	Kind int
	Traits uint64
	Behavior *Behavior
}

type Behavior struct {
	Path []Point
	Guard, Target Point
	State int
	SkipTurn bool
}

type Spirit struct {
	Level, Charges int
	MaxCharges [2]int
	Ability [2]any
	BonusAttack, BonusDefense [2]int
	BonusTraits [2]uint64
	BonusHP [2]int
	Uses int
	Advanced bool
}

type EmptyTotem struct{}
type Comestible struct { Effect any }
type Menhir struct { Used bool; Effect any }
type Portal struct { Fake, Used bool }
type CorruptionOrb struct { Broken bool }
type RunicTrap struct { Used, KnownUsed bool; Rune int }

// All effect types in encoding.go's native save registry. Action types belong
// only to the separate key configuration format, not Game, and are not loaded.
type EffectAmbrosiaBerries struct { HealingCombat bool }
type EffectBerserkingFlower struct{}
type EffectLignificationFruit struct{}
type EffectClarityLeaves struct { HealingCombat bool }
type EffectFoggySkinOnion struct { HealingCombat bool }
type EffectFirebreathPepper struct { HealingCombat bool }
type EffectTeleportMushroom struct { HealingCombat bool }
type EffectFocus struct{}
type EffectDig struct{}
type EffectJump struct{}
type EffectPushingGale struct{}
type EffectTimeStop struct{}
type EffectTailSlap struct{}
type EffectVampirism struct { Duration int }
type EffectLightning struct{}
type EffectBark struct{}
type EffectNoxiousSmell struct{}
type EffectLignify struct{}
type EffectPoisonCloud struct{}
type EffectSprint struct{}
type EffectFireRetreat struct{}
type EffectShadows struct{}
type EffectSnack struct { NoGluttonyStatus bool }
type EffectGarden struct{}
type EffectStomp struct{}
type EffectDeathStare struct{}
type EffectLayRune struct{}
type EffectDisorient struct{}
type EffectEarthMenhir struct{}
type EffectWarpingMenhir struct{}
type EffectPoisonMenhir struct{}
type EffectFireMenhir struct{}

func init() {
	// These ordinary named types are in package main, exactly like upstream.
	// Gob's default registration names are *main.Actor, main.EffectFocus, etc.
	for _, value := range []any{
		&Actor{}, &Spirit{}, &EmptyTotem{}, &Comestible{}, &Menhir{},
		&Portal{}, &CorruptionOrb{}, &RunicTrap{},
		EffectAmbrosiaBerries{}, EffectBerserkingFlower{}, EffectLignificationFruit{},
		EffectClarityLeaves{}, EffectFoggySkinOnion{}, EffectFirebreathPepper{},
		EffectTeleportMushroom{}, EffectFocus{}, EffectDig{}, EffectJump{},
		EffectPushingGale{}, EffectTimeStop{}, EffectTailSlap{}, EffectVampirism{},
		EffectLightning{}, EffectBark{}, EffectNoxiousSmell{}, EffectLignify{},
		EffectPoisonCloud{}, EffectSprint{}, EffectFireRetreat{}, EffectShadows{},
		EffectSnack{}, EffectGarden{}, EffectStomp{}, EffectDeathStare{},
		EffectLayRune{}, EffectDisorient{}, EffectEarthMenhir{},
		EffectWarpingMenhir{}, EffectPoisonMenhir{}, EffectFireMenhir{},
	} {
		gob.Register(value)
	}
}

// Tag interfaces in JSON: empty effects would otherwise all collapse to {},
// masking changes in spirit abilities or item effects across native restores.
type typedValue struct {
	Type string
	State any
}

func tagged(value any) any {
	if value == nil {
		return nil
	}
	return typedValue{Type: reflect.TypeOf(value).String(), State: value}
}

func (e Entity) MarshalJSON() ([]byte, error) {
	type plain Entity
	return json.Marshal(struct {
		*plain
		Role any
	}{plain: (*plain)(&e), Role: tagged(e.Role)})
}

func (s Spirit) MarshalJSON() ([]byte, error) {
	type plain Spirit
	return json.Marshal(struct {
		*plain
		Ability [2]any
	}{plain: (*plain)(&s), Ability: [2]any{tagged(s.Ability[0]), tagged(s.Ability[1])}})
}

func (c Comestible) MarshalJSON() ([]byte, error) {
	return json.Marshal(struct { Effect any }{Effect: tagged(c.Effect)})
}

func (m Menhir) MarshalJSON() ([]byte, error) {
	return json.Marshal(struct { Used bool; Effect any }{Used: m.Used, Effect: tagged(m.Effect)})
}

type Map struct {
	Terrain, KnownTerrain Grid
	FOV *FOV
	FOVPts []Point
	Clouds *CloudGrid
	Level int
	Noise PointNoise
	Waypoints []Point
	BoolCache []bool
	ActorCache, RuneCache []int32
	Orb, Portal, Totem Point
}

type Cloud struct { Kind int; P Point; Duration int }
type CloudGrid struct { Clouds []Cloud; Grid []int }

type PointNoise map[Point]int

func (noise PointNoise) MarshalJSON() ([]byte, error) {
	if noise == nil {
		return []byte("null"), nil
	}
	type entry struct { P Point; Kind int }
	entries := make([]entry, 0, len(noise))
	for point, kind := range noise {
		entries = append(entries, entry{P: point, Kind: kind})
	}
	sort.Slice(entries, func(i, j int) bool {
		if entries[i].P.Y != entries[j].P.Y {
			return entries[i].P.Y < entries[j].P.Y
		}
		return entries[i].P.X < entries[j].P.X
	})
	return json.Marshal(entries)
}

// rl.Grid is a custom gob payload encoding innerGrid, not a public struct.
// Decode the payload instead of comparing its unstable raw gob bytes. Ug.Cells
// is the complete native row-major []rl.Cell (int32); Rg retains slice bounds.
type Grid struct { Ug *CellGrid; Rg Range }
type CellGrid struct { Cells []int32; Width, Height int }

func (grid *Grid) GobDecode(payload []byte) error {
	type innerGrid Grid
	var native innerGrid
	if err := gob.NewDecoder(bytes.NewReader(payload)).Decode(&native); err != nil {
		return fmt.Errorf("grid payload: %w", err)
	}
	*grid = Grid(native)
	return nil
}

// FOV and PathRange also have custom gob payloads. Mirrors below retain all
// their exported inner fields, including caches; unexported closures cannot
// occur in the wire encoding. No cached point-key maps are omitted.
type LightNode struct { P Point; Cost int }
type FOV struct {
	Costs []int
	ShadowCasting []bool
	Lighted []LightNode
	Visibles []Point
	RayCache []LightNode
	Rg Range
	Src Point
	Capacity int
}

func (fov *FOV) GobDecode(payload []byte) error {
	type innerFOV FOV
	var native innerFOV
	if err := gob.NewDecoder(bytes.NewReader(payload)).Decode(&native); err != nil {
		return fmt.Errorf("FOV payload: %w", err)
	}
	*fov = FOV(native)
	return nil
}

type PathNode struct {
	Open, Closed bool
	Parent, P Point
	Cost, Rank, Idx, Estimation, CacheIndex int
}
type NodeMap struct { Nodes []PathNode; Idx int }
type Node struct { P Point; Cost int }
type PathRange struct {
	AstarNodes, DijkstraNodes *NodeMap
	DijkstraIterNodes []Node
	BfMap []int
	BfQueue []Node
	CC, CCStack []int
	CCIterCache []Point
	AstarQueue, DijkstraQueue []*PathNode
	Rg Range
	DijkstraUnreachable, BfUnreachable, BfEnd, W, Capacity int
}

func (pr *PathRange) GobDecode(payload []byte) error {
	type innerPathRange PathRange
	var native innerPathRange
	if err := gob.NewDecoder(bytes.NewReader(payload)).Decode(&native); err != nil {
		return fmt.Errorf("path range payload: %w", err)
	}
	*pr = PathRange(native)
	return nil
}

type ProcInfo struct {
	Layouts []int
	Earthquake int
	FakePortal []bool
	GuardianEarly, GuardianTotem1, GuardianTotem2 int
	GuardianPortal1, GuardianPortal2 int
	WanderingUnique1, WanderingUnique2 int
	MonsEarly, MonsMid, MonsMidLate, MonsLate, MonsLateSwarm int
	ThemedLevel, TrapLevel int
	Spirits []SpiritProcInfo
	Menhirs []int
	MenhirIdx int
	Comestibles []int
	ComestibleIdx int
	NComestibles, NMenhirs []int
	Runes []int
	RuneIdx int
}
type SpiritProcInfo struct { Idx int; Advanced bool }

type Logs struct { Story []string; Entries []LogEntry; Index, NextTick int }
type LogEntry struct { Text, MText string; Index int; Tick bool; Style, Dups int }
type Wizard struct { Mode, Resurrections int; Extra bool }

type Stats struct {
	ActivatedMenhirs int
	Comestibles map[string]int
	Cornered, Damage int
	Deaths map[string]int
	Digs, EatenComestibles, FireClouds, Hits, Hurt, Lucky, Misses int
	MonsterTrapTriggers, NDeaths, PlayerTrapTriggers, PoisonClouds, SpiritUses int
	Statuses []int
	Waits, WallJumps, WallThroughs int
	MapTurns, MapExplorePerc, MapDeathPerc, MapDamage [MapLevels]int
	MapEatenComestibles, MapSpiritUses, MapActivatedMenhirs, MapTriggeredTraps [MapLevels]int
}

func validateGrid(name string, grid Grid) error {
	if grid.Ug == nil || grid.Ug.Width != MapWidth || grid.Ug.Height != MapHeight ||
		len(grid.Ug.Cells) != MapWidth*MapHeight || grid.Rg.Min != (Point{}) ||
		grid.Rg.Max != (Point{X: MapWidth, Y: MapHeight}) {
		return fmt.Errorf("missing or incompatible %s: expected %dx%d native grid", name, MapWidth, MapHeight)
	}
	return nil
}

func decode(path string) (*Game, error) {
	file, err := os.Open(path) // never create, rewrite, consume or remove saves
	if err != nil {
		return nil, err
	}
	defer file.Close()
	stream, err := zlib.NewReader(file)
	if err != nil {
		return nil, err
	}
	defer stream.Close()
	var game Game
	if err := gob.NewDecoder(stream).Decode(&game); err != nil {
		return nil, err
	}
	// Read the remainder to verify the zlib checksum, which gob.Decode may not
	// reach when it finishes decoding the object at the end of the stream.
	if _, err := io.Copy(io.Discard, stream); err != nil {
		return nil, err
	}
	if game.Version != Version {
		return nil, fmt.Errorf("unsupported save version %q (expected %s)", game.Version, Version)
	}
	if game.Map == nil || game.PR == nil || game.PRnoise == nil || game.Logs == nil ||
		game.ProcInfo == nil || game.Stats == nil || game.Map.FOV == nil || game.Map.Clouds == nil {
		return nil, fmt.Errorf("save lacks required game/map pointers")
	}
	if len(game.Entities) <= PlayerID || game.Entities[PlayerID] == nil {
		return nil, fmt.Errorf("save lacks player entity at index %d", PlayerID)
	}
	player, ok := game.Entities[PlayerID].Role.(*Actor)
	if !ok || player == nil || player.Kind != 0 || len(player.Statuses) != NStatuses {
		return nil, fmt.Errorf("save lacks valid player actor at index %d", PlayerID)
	}
	if err := validateGrid("Terrain", game.Map.Terrain); err != nil {
		return nil, err
	}
	if err := validateGrid("KnownTerrain", game.Map.KnownTerrain); err != nil {
		return nil, err
	}
	return &game, nil
}

func main() {
	if len(os.Args) < 2 {
		fmt.Fprintln(os.Stderr, "usage: shamogu-save-reader SAVE [SAVE ...]")
		os.Exit(2)
	}
	encoder := json.NewEncoder(os.Stdout)
	// encoding/json sorts string-keyed maps; PointNoise sorts coordinate keys.
	for _, path := range os.Args[1:] {
		game, err := decode(path)
		if err != nil {
			fmt.Fprintf(os.Stderr, "%s: %v\n", path, err)
			os.Exit(1)
		}
		if err := encoder.Encode(game); err != nil {
			fmt.Fprintf(os.Stderr, "%s: JSON encoding: %v\n", path, err)
			os.Exit(1)
		}
	}
}
