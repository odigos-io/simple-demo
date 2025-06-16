package dev.keyval.kvshop.frontend;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
public class ProductController {

    private final CurrencyService currencyService;
    private final GeoService geoService;
    private final InventoryService inventoryService;
    private final PricingService pricingService;
    private final CouponService couponService;

    @Autowired
    public ProductController(
            CurrencyService currencyService,
            GeoService geoService,
            InventoryService inventoryService,
            PricingService pricingService,
            CouponService couponService) {
        this.currencyService = currencyService;
        this.geoService = geoService;
        this.inventoryService = inventoryService;
        this.pricingService = pricingService;
        this.couponService = couponService;
    }

    @CrossOrigin(origins = "*")
    @GetMapping("/rate/{currencyPair}")
    public String getConversionRate(@PathVariable String currencyPair) {
        CurrencyResult currencyInfo = this.currencyService.getCurrencyInfo(currencyPair);
        String currencyString = currencyInfo.getConvertedString();

        System.out.println("Currency conversion rate: " + currencyString);

        return currencyString;
    }

    @CrossOrigin(origins = "*")
    @GetMapping("/products")
    public List<Product> getProducts() {
        List<Product> products = this.inventoryService.getInventory();

        // Add price to every product
        for (Product product : products) {
            product.setPrice(this.pricingService.getPrice(product.getId()));
        }

        // Get coupons
        this.couponService.getCoupons();

        return products;
    }

    @CrossOrigin(origins = "*")
    @PostMapping("/buy")
    public void buyProduct(@RequestParam(name = "id") int id) {
        // TODO: remove GEO from Java once context propagation is fixed for PHP
        GeoResult locationInfo = this.geoService.getLocationInfo("israel");
        String origin = locationInfo.getOrigin();
        System.out.println("TEMP - got geo result : " + origin);

        // Validate price via pricing service
        double price = this.pricingService.getPrice(id);

        String currencyPair = "usd-eur";
        CurrencyResult currencyInfo = this.currencyService.getCurrencyInfo(currencyPair);
        int conversionRate = currencyInfo.getConversionRate();

        String usdPrice = ("$" + price + " USD");
        String eurPrice = ("ִ€" + (price * conversionRate) + " EUR");
        System.out.println("Buying product with id " + id + " for " + usdPrice + " (converted to ִִִ" + eurPrice + ")");

        // Call inventory service to buy product
        this.inventoryService.buy(id);

        // Apply coupon
        this.couponService.applyCoupon();
    }
}
