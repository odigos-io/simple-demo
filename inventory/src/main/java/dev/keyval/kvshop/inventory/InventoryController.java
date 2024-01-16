package dev.keyval.kvshop.inventory;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
public class InventoryController {

    private static final List<InventoryItem> items = loadItems();

    @GetMapping("/inventory")
    public List<InventoryItem> getInventory() {
        System.out.println("Returning inventory");
        return items;
    }

    @PostMapping("/buy")
    public void buyProduct(@RequestParam int id) throws InterruptedException {
        System.out.println("Buying product with id " + id);
        Thread.sleep(1000);
    }

    private static List<InventoryItem> loadItems() {
        return List.of(
            new InventoryItem(1, "T Shirt", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f455.png"),
            new InventoryItem(2, "Pants", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f456.png"),
            new InventoryItem(3, "Shoes", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f462.png"),
            new InventoryItem(4, "Hat", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f9e2.png"),
            new InventoryItem(5, "Socks", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f9e6.png"),
            new InventoryItem(6, "Gloves", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f9e4.png"),
            new InventoryItem(7, "Scarf", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f9e3.png"),
            new InventoryItem(8, "Jacket", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f9e5.png"),
            new InventoryItem(9, "Kimono", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f458.png"),
            new InventoryItem(10, "Purse", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f45b.png"),
            new InventoryItem(11, "Tophat", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f3a9.png"),
            new InventoryItem(12, "Watch", "https://emoji.aranja.com/static/emoji-data/img-apple-160/231a.png"),
            new InventoryItem(13, "Sunglasses", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f576-fe0f.png"),
            new InventoryItem(14, "Womans Hat", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f452.png"),
            new InventoryItem(15, "Sandal", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f461.png"),
            new InventoryItem(16, "Bracelet", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f4ff.png"),
            new InventoryItem(17, "Ring", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f48d.png"),
            new InventoryItem(18, "Suit", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f454.png"),
            new InventoryItem(19, "Dress", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f457.png"),
            new InventoryItem(20, "Eyeglasses", "https://emoji.aranja.com/static/emoji-data/img-apple-160/1f453.png")
        );
    }

}
