package dev.keyval.kvshop.frontend;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class CurrencyService {
    private final String currencyServiceHost;
    private static final Logger log = LoggerFactory.getLogger(CurrencyService.class);

    public CurrencyService(@Value("${CURRENCY_SERVICE_HOST}") String currencyServiceHost) {
        this.currencyServiceHost = currencyServiceHost;
    }

    public CurrencyResult getCurrencyInfo(String currencyPair) {
        String url = "http://" + currencyServiceHost + "/rate/" + currencyPair;
        CurrencyResult res = new RestTemplate().getForObject(url, CurrencyResult.class);

        log.info("Successfully fetched from Currency service, got result: {}", res.getConvertedString());

        return res;
    }
}
