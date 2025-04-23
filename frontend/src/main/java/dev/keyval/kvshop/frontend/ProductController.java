package dev.keyval.kvshop.frontend;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
public class ProductController {

    private final CurrencyService currencyService;
    private final InventoryService inventoryService;
    private final PricingService pricingService;
    private final CouponService couponService;

    @Autowired
    public ProductController(CurrencyService currencyService, InventoryService inventoryService,
            PricingService pricingService, CouponService couponService) {
        this.currencyService = currencyService;
        this.inventoryService = inventoryService;
        this.pricingService = pricingService;
        this.couponService = couponService;
    }

    @CrossOrigin(origins = "*")
    @GetMapping("/usd-ils")
    public int getUsdIlsConversion() {
        int ilsConversionRate = currencyService.getUsdIlsConversion();

        return ilsConversionRate;
    }

    @CrossOrigin(origins = "*")
    @GetMapping("/products")
    public List<Product> getProducts() {
        List<Product> products = inventoryService.getInventory();

        // Add price to every product
        for (Product product : products) {
            product.setPrice(pricingService.getPrice(product.getId()));
        }

        // Get coupons
        this.couponService.getCoupons();

        return products;
    }

    @CrossOrigin(origins = "*")
    @PostMapping("/buy")
    public void buyProduct(@RequestParam(name = "id") int id) {
        // Validate price via pricing service
        double price = pricingService.getPrice(id);
        int ilsConversionRate = currencyService.getUsdIlsConversion();

        String usdPrice = ("$" + price + " USD");
        String ilsPrice = ("ִ₪" + (price * ilsConversionRate) + " ILS");
        System.out.println("Buying product with id " + id + " for " + usdPrice + " (converted to ִִִ" + ilsPrice + ")");

        // Call inventory service to buy product
        this.inventoryService.buy(id);

        // Apply coupon
        this.couponService.applyCoupon();
    }
}
