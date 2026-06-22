package dev.keyval.kvshop.frontend;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class ShippingService {
    private final String shippingServiceHost;
    private static final Logger log = LoggerFactory.getLogger(ShippingService.class);

    public ShippingService(@Value("${SHIPPING_SERVICE_HOST}") String shippingServiceHost) {
        this.shippingServiceHost = shippingServiceHost;
    }

    public ShippingQuoteResult getQuote(int productId) {
        String url = ServiceUrl.build(shippingServiceHost, "/quote?id=" + productId);
        ShippingQuoteResult res = new RestTemplate().getForObject(url, ShippingQuoteResult.class);
        log.info("Shipping quote for product {}: {} cents ({})", productId,
                res != null ? res.getShippingCents() : -1,
                res != null ? res.getCarrier() : "n/a");
        return res;
    }
}
