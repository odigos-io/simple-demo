package dev.keyval.kvshop.pricing;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class PricingController {

    @GetMapping("/price")
    public PriceResult getPrice(@RequestParam int id) {
        // Random double between 1 and 50
        double price = Math.random() * 50 + 1;

        // Round to 2 decimal places
        price = Math.round(price * 100.0) / 100.0;

        return new PriceResult(id, price);
    }
}
