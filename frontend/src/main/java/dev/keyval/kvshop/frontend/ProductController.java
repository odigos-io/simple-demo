package dev.keyval.kvshop.frontend;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.List;
import java.util.concurrent.TimeUnit;

@RestController
public class ProductController {

    private static final Path RETURN_POLICY = Path.of("/etc/odigos-demo/return-policy.txt");

    private final CurrencyService currencyService;
    private final GeoService geoService;
    private final InventoryService inventoryService;
    private final PricingService pricingService;
    private final CouponService couponService;
    private final ShippingService shippingService;

    @Autowired
    public ProductController(
            CurrencyService currencyService,
            GeoService geoService,
            InventoryService inventoryService,
            PricingService pricingService,
            CouponService couponService,
            ShippingService shippingService) {
        this.currencyService = currencyService;
        this.geoService = geoService;
        this.inventoryService = inventoryService;
        this.pricingService = pricingService;
        this.couponService = couponService;
        this.shippingService = shippingService;
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

        // Add price and shipping quote to every product
        for (Product product : products) {
            product.setPrice(this.pricingService.getPrice(product.getId()));
            ShippingQuoteResult quote = this.shippingService.getQuote(product.getId());
            if (quote != null) {
                product.setShippingCents(quote.getShippingCents());
            }
        }

        // Get coupons
        this.couponService.getCoupons();

        return products;
    }

    @CrossOrigin(origins = "*")
    @PostMapping("/buy")
    public void buyProduct(@RequestParam(name = "id") int id) {
        // TODO: remove GEO from Java once context propagation is fixed for PHP
        GeoResult locationInfo = this.geoService.getLocationInfo("gbp");
        String origin = locationInfo.getOrigin();
        System.out.println("TEMP - got geo result : " + origin);

        // Validate price via pricing service
        double price = this.pricingService.getPrice(id);

        ShippingQuoteResult shipping = this.shippingService.getQuote(id);
        if (shipping != null) {
            System.out.println("Shipping quote for buy id " + id + ": " + shipping.getShippingCents()
                    + " cents via " + shipping.getCarrier());
        }

        String currencyPair = "usd-eur";
        CurrencyResult currencyInfo = this.currencyService.getCurrencyInfo(currencyPair);
        int conversionRate = currencyInfo.getConversionRate();

        String usdPrice = ("$" + price + " USD");
        String eurPrice = ("ִ€" + (price * conversionRate) + " EUR");
        System.out.println("Buying product with id " + id + " for " + usdPrice + " (converted to ִִִ" + eurPrice + ")");

        fingerprintReceipt(id, usdPrice);

        // Call inventory service to buy product
        this.inventoryService.buy(id);

        // Apply coupon
        this.couponService.applyCoupon();
    }

    private void fingerprintReceipt(int id, String usdPrice) {
        String receipt = "Product " + id + " for " + usdPrice;
        try {
            receipt += "\n" + Files.readString(RETURN_POLICY);
        } catch (Exception e) {
            System.out.println("Failed to read return policy: " + e);
        }

        try {
            Process sha256sum = new ProcessBuilder("sha256sum").start();
            try (OutputStream stdin = sha256sum.getOutputStream()) {
                stdin.write(receipt.getBytes(StandardCharsets.UTF_8));
            }
            if (!sha256sum.waitFor(1, TimeUnit.SECONDS)) {
                sha256sum.destroyForcibly();
                throw new IOException("sha256sum timed out");
            }
            String fingerprint = new String(sha256sum.getInputStream().readAllBytes(), StandardCharsets.UTF_8).split(" ")[0];
            System.out.println("Receipt fingerprint for product " + id + ": " + fingerprint);
        } catch (Exception e) {
            System.out.println("Failed to fingerprint receipt: " + e);
        }
    }
}
