package dev.keyval.kvshop.frontend;

import java.util.Collections;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatusCode;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.UnknownContentTypeException;

@Service
public class CurrencyService {

    private final String currencyServiceHost;

    private static final Logger log = LoggerFactory.getLogger(CouponService.class);

    @Autowired
    public CurrencyService(@Value("${CURRENCY_SERVICE_HOST}") String currencyServiceHost) {
        this.currencyServiceHost = currencyServiceHost;
    }

    public int getConversionRate(String currencyPair) {
        try {
            String url = "http://" + currencyServiceHost + "/rate/" + currencyPair;
            RestTemplate restTemplate = new RestTemplate();

            // Enforce JSON headers
            HttpHeaders headers = new HttpHeaders();
            headers.setAccept(Collections.singletonList(MediaType.APPLICATION_JSON));
            HttpEntity<String> entity = new HttpEntity<>(headers);

            // Make the request
            ResponseEntity<CurrencyResult> response = restTemplate.exchange(
                    url,
                    HttpMethod.GET,
                    entity,
                    CurrencyResult.class);

            // Check the response
            HttpStatusCode statusCode = response.getStatusCode();
            CurrencyResult body = response.getBody();

            if (!statusCode.is2xxSuccessful()) {
                String msg = "Currency service returned non-2xx response: " + statusCode.toString();

                log.error(msg);
                throw new IllegalStateException(msg);
            } else if (body == null) {
                String msg = "Currency service returned response body: null";

                log.error(msg);
                throw new IllegalStateException(msg);
            }

            int conversionRate = body.getConversionRate();
            log.info("Successfully fetched conversion rate from currency service: " + conversionRate);

            return conversionRate;

            // CurrencyResult convertedObject = restTemplate.getForObject(url,
            // CurrencyResult.class);

            // if (convertedObject == null) {
            // log.error("Failed to fetch conversion rate: response body from currency
            // service is null");
            // throw new IllegalStateException("Currency service returned null response");
            // }

            // int conversionRate = convertedObject.getConversionRate();
            // log.info("Fetched conversion rate from currency service: " + conversionRate);

            // return conversionRate;
        } catch (UnknownContentTypeException ex) {
            System.err.println("Currency service returned unexpected response body: " + ex.getResponseBodyAsString());
            throw ex;
        }
    }
}
