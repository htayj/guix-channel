// SPDX-License-Identifier: GPL-3.0-or-later
// Build-only launcher for AloneRL's upstream Jupiter tests.
import java.io.PrintWriter;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashSet;

import org.junit.platform.engine.discovery.DiscoverySelectors;
import org.junit.platform.launcher.core.LauncherDiscoveryRequestBuilder;
import org.junit.platform.launcher.core.LauncherFactory;
import org.junit.platform.launcher.listeners.SummaryGeneratingListener;

final class AloneRlTestLauncher {
    public static void main(String[] args) {
        if (args.length == 0) {
            throw new IllegalArgumentException("Supply the compiled upstream test directory");
        }
        var roots = new LinkedHashSet<Path>();
        for (String argument : args) {
            Path root = Path.of(argument).toAbsolutePath().normalize();
            if (!Files.isDirectory(root)) {
                throw new IllegalArgumentException("Missing compiled test directory: " + root);
            }
            roots.add(root);
        }
        var request = LauncherDiscoveryRequestBuilder.request()
                .selectors(DiscoverySelectors.selectClasspathRoots(roots))
                .build();
        var listener = new SummaryGeneratingListener();
        LauncherFactory.create().execute(request, listener);
        var summary = listener.getSummary();
        var writer = new PrintWriter(System.out, true);
        summary.printTo(writer);
        summary.printFailuresTo(writer);
        writer.flush();
        if (summary.getTestsFoundCount() == 0 || summary.getTotalFailureCount() != 0) {
            System.exit(1);
        }
    }
}
