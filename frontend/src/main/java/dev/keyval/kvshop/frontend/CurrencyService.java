package dev.keyval.kvshop.frontend;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class CurrencyService {

    private final String currencyServiceHost;

    private static final Logger log = LoggerFactory.getLogger(CouponService.class);

    @Autowired
    public CurrencyService(@Value("${CURRENCY_SERVICE_HOST}") String currencyServiceHost) {
        this.currencyServiceHost = currencyServiceHost;
    }

    public int getCurrency() {
        RestTemplate restTemplate = new RestTemplate();

        String url = "http://" + currencyServiceHost + "/currency";
        CurrencyResult res = restTemplate.getForObject(url, CurrencyResult.class);

        int currency = res.getCurrency();
        log.info("Fetched currency from currency service, got result: {}", currency);

        return currency;
    }
}
