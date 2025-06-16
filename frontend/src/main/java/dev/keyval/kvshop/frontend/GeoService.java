package dev.keyval.kvshop.frontend;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class GeoService {
    private final String geoServiceHost;
    private static final Logger log = LoggerFactory.getLogger(GeoService.class);

    public GeoService(@Value("${GEOLOCATION_SERVICE_HOST}") String geoServiceHost) {
        this.geoServiceHost = geoServiceHost;
    }

    public GeoResult getLocationInfo(String loc) {
        String url = "http://" + geoServiceHost + "/location/" + loc;
        GeoResult res = new RestTemplate().getForObject(url, GeoResult.class);

        log.info("Successfully fetched from Geolocation service, got result: {}", res.toString());

        return res;
    }
}
