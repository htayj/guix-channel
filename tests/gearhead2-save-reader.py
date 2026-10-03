#!/usr/bin/env python3
"""Read, never modify, v0.701 GearHead2's native Pascal text saves.

Grammar: narration.pp WriteCampaign/ReadCampaign; locale.pp WriteMap/ReadMap;
415dee8d8730ef1ed8adfd741b1a2b2fa201c2e7. Canonicalize keyed numeric
attributes and named frozen-map order: ReadCampaign prepends each frozen map,
reversing the serialized list; lookup is by name. Gear, inventory, component
and complete raw string-record ordering remains significant. Stat entries are
stored deviations from InitGear defaults, not invented default values.
No runtime RNG, UI caches or unserialized fields are claimed by this decoder.
"""
import json
from pathlib import Path
import sys


class Reader:
    def __init__(self, path):
        self.lines = Path(path).read_text(encoding='utf-8').splitlines()
        self.index = 0

    def line(self):
        if self.index >= len(self.lines):
            raise ValueError('truncated native save at line ' + str(self.index + 1))
        result = self.lines[self.index]
        self.index += 1
        return result

    def integer(self):
        return int(self.line().strip())

    def map(self, width, height):
        size = width * height
        if not (0 < width <= 255 and 0 < height <= 255):
            raise ValueError('invalid native map dimensions')
        if self.line() != '*** GearHead Location Record ***':
            raise ValueError('missing native map marker')
        terrain = []
        while len(terrain) < size:
            count, value = self.integer(), self.integer()
            if count <= 0 or count > size - len(terrain):
                raise ValueError('invalid terrain RLE count')
            terrain.extend([value] * count)
        if self.line() != '***':
            raise ValueError('missing native visibility marker')
        visible, value = [], False
        while len(visible) < size:
            count = self.integer()
            if count < 0 or count > size - len(visible):
                raise ValueError('invalid visibility RLE count')
            visible.extend([value] * count)
            value = not value
        return {'terrain': terrain, 'visible': visible}

    def gears(self):
        result = []
        while True:
            fields = list(map(int, self.line().split()))
            if fields == [-1]:
                return result
            if len(fields) != 5 or fields[0] != 0:
                raise ValueError('invalid compact gear header')
            stats_line = self.line().split()
            if not stats_line or stats_line[0] != 'Stats' or len(stats_line) % 2 != 1:
                raise ValueError('invalid compact gear stats')
            stats = {}
            for index in range(1, len(stats_line), 2):
                key, value = int(stats_line[index]), int(stats_line[index + 1])
                if str(key) in stats:
                    raise ValueError('duplicate native stat')
                stats[str(key)] = value
            na = {}
            while True:
                attribute = list(map(int, self.line().split()))
                if attribute == [-1]:
                    break
                if len(attribute) != 4 or attribute[0] != 0:
                    raise ValueError('invalid native numeric attribute')
                key = '%d,%d' % (attribute[1], attribute[2])
                if key in na:
                    raise ValueError('duplicate native numeric attribute')
                na[key] = attribute[3]
            sa, sa_records = {}, []
            while True:
                attribute = self.line()
                if attribute == 'Z':
                    break
                # WriteCGears retains the entire Info line. RetrieveAString
                # (texutil.pp:175-194) permits no closing '>' and otherwise
                # ends at the FIRST '>', not necessarily at end-of-line.
                opening = attribute.find('<')
                if opening < 0 or not attribute[:opening].strip():
                    raise ValueError('invalid native string attribute')
                key = attribute.split()[0].upper()
                closing = attribute.find('>')
                # SAttValue selects the first matching label, but the native
                # file can contain duplicates; retain every full Info record.
                value = attribute[opening + 1:closing if closing >= 0 else None]
                sa.setdefault(key, value)
                sa_records.append(attribute)
            result.append({'kind': fields[1:], 'stats': stats, 'na': na, 'sa': sa,
                           'sa_records': sa_records,
                           'inventory': self.gears(), 'subcomponents': self.gears()})

    def finish(self):
        if any(line.strip() for line in self.lines[self.index:]):
            raise ValueError('unparsed data remains in native save')


def read_campaign(path):
    reader = Reader(path)
    width = reader.integer()
    if width <= 0:
        raise ValueError('expected a playable RPG campaign gameboard')
    height, clock, scale = reader.integer(), reader.integer(), reader.integer()
    active_map = reader.map(width, height)
    scene_index, actors = reader.integer(), reader.gears()
    frozen = []
    while True:
        marker = reader.integer()
        if marker == -1:
            break
        if marker != 1:
            raise ValueError('invalid native frozen map marker')
        name = reader.line()
        frozen_width, frozen_height = reader.integer(), reader.integer()
        frozen.append({'name': name, 'width': frozen_width, 'height': frozen_height,
                       'map': reader.map(frozen_width, frozen_height)})
    source = reader.gears()
    reader.finish()
    names = [item['name'] for item in frozen]
    if len(set(names)) != len(names):
        raise ValueError('duplicate native frozen map name')
    frozen.sort(key=lambda item: item['name'])
    return {'width': width, 'height': height, 'time': clock, 'scale': scale,
            'map': active_map, 'scene_index': scene_index, 'actors': actors,
            'frozen_maps': frozen, 'source': source}


def read_pilot(path):
    reader = Reader(path)
    result = reader.gears()
    reader.finish()
    return result


def walk_gears(gears):
    for gear in gears:
        yield gear
        yield from walk_gears(gear['inventory'])
        yield from walk_gears(gear['subcomponents'])


def pilot(campaign, name):
    matches = [gear for gear in walk_gears(campaign['actors'])
               if gear['sa'].get('NAME') == name]
    if len(matches) != 1:
        raise ValueError('expected exactly one active pilot named ' + name)
    return matches[0]


if __name__ == '__main__':
    if len(sys.argv) != 2:
        raise SystemExit('usage: gearhead2-save-reader.py NATIVE-RPG-SAVE')
    print(json.dumps(read_campaign(sys.argv[1]), sort_keys=True, indent=2))
