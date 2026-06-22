package dev.keyval.kvshop.frontend;

public final class ServiceUrl {

    private ServiceUrl() {
    }

    public static String build(String endpoint, String path) {
        String base = endpoint;
        if (!base.startsWith("http://") && !base.startsWith("https://")) {
            base = "http://" + base;
        }
        if (path == null || path.isEmpty()) {
            return base;
        }
        if (!path.startsWith("/")) {
            path = "/" + path;
        }
        return base + path;
    }
}
