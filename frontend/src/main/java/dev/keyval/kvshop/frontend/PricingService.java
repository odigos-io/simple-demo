package dev.keyval.kvshop.frontend;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class PricingService {

    private final String pricingServiceHost;

    @Autowired
    public PricingService(@Value("${PRICING_SERVICE_HOST}") String pricingServiceHost) {
        this.pricingServiceHost = pricingServiceHost;
    }

    public double getPrice(int id) {
        // Make http request to pricing service
        RestTemplate restTemplate = new RestTemplate();
        PriceResult priceResult = restTemplate.getForObject("http://" + pricingServiceHost + "/price?id=" + id, PriceResult.class);
        return priceResult.getPrice();
    }
}
