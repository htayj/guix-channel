#!@SH@
# All assets are classpath resources; the upstream desktop launcher owns XDG
# preferences and save paths.  No files are written beside the store jars.
PATH="@ZENITY@/bin:@XDG@/bin:@WHICH@/bin${PATH:+:$PATH}"
export PATH
exec "@JAVA@" \
    "-Dorg.lwjgl.librarypath=@LWJGL@/lib" \
    "-Dexppd.native.path=@GDX@/lib:@CONTROLLERS@/lib" \
    -classpath "@GAME@:@GDX@/share/java/gdx.jar:@LWJGL@/share/java/lwjgl.jar:@CONTROLLERS@/share/java/gdx-controllers.jar:@JSON@/share/java/json.jar" \
    com.shatteredpixel.shatteredpixeldungeon.desktop.DesktopLauncher "$@"
