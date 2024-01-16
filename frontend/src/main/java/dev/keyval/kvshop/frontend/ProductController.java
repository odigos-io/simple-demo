package dev.keyval.kvshop.frontend;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
public class ProductController {

    private final InventoryService inventoryService;
    private final PricingService pricingService;
    private final CouponService couponService;

    @Autowired
    public ProductController(InventoryService inventoryService, PricingService pricingService, CouponService couponService) {
        this.inventoryService = inventoryService;
        this.pricingService = pricingService;
        this.couponService = couponService;
    }

    @CrossOrigin(origins = "http://localhost:3000")
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

    @CrossOrigin(origins = "http://localhost:3000")
    @PostMapping("/buy")
    public void buyProduct(@RequestParam(name ="id") int id) {
        // Validate price via pricing service
        double price = pricingService.getPrice(id);
        System.out.println("Buying product with id " + id + " for $" + price);

        // Call inventory service to buy product
        this.inventoryService.buy(id);

        // Apply coupon
        this.couponService.applyCoupon();
    }
}
