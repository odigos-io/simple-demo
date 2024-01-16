package dev.keyval.kvshop.frontend;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class CouponService {

    private final String couponServiceHost;

    private static final Logger log = LoggerFactory.getLogger(CouponService.class);

    public CouponService(@Value("${COUPON_SERVICE_HOST}") String couponServiceHost) {
        this.couponServiceHost = couponServiceHost;
    }

    public CouponResult getCoupons() {
        // Make http request to coupon service
        RestTemplate restTemplate = new RestTemplate();
        CouponResult res = restTemplate.getForObject("http://" + couponServiceHost + "/coupons", CouponResult.class);
        log.info("Fetched coupons from coupon service, got result: {}", res.getCoupon());
        return res;
    }

    public CouponResult applyCoupon() {
        // Make http request to coupon service
        RestTemplate restTemplate = new RestTemplate();
        CouponResult res = restTemplate.postForObject("http://" + couponServiceHost + "/apply-coupon", null, CouponResult.class);
        log.info("Applied coupon to coupon service, got result: {}", res.getCoupon());
        return res;
    }
}
