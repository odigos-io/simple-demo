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

    public int getConversionRate(String currencyPair) {
        String url = "http://" + currencyServiceHost + "/rate/" + currencyPair;
        CurrencyResult res = (new RestTemplate()).getForObject(url, CurrencyResult.class);

        int conversionRate = res.getConversionRate();
        log.info("Fetched conversion rate from currency service, got result:" + conversionRate);

        return conversionRate;
    }
}
