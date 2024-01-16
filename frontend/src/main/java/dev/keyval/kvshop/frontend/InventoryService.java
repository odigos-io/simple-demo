package dev.keyval.kvshop.frontend;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;

@Service
public class InventoryService {

    private final String inventoryServiceHost;

    public InventoryService(@Value("${INVENTORY_SERVICE_HOST}") String inventoryServiceHost) {
        this.inventoryServiceHost = inventoryServiceHost;
    }

    public List<Product> getInventory() {
        // Make http request to product service
        RestTemplate restTemplate = new RestTemplate();
        Product[] result = restTemplate.getForObject("http://" + inventoryServiceHost + "/inventory", Product[].class);

        // Convert result to list of products
        return Arrays.asList(result);
    }

    public void buy(int id) {
        // Make http request to product service
        RestTemplate restTemplate = new RestTemplate();
        restTemplate.postForObject("http://" + inventoryServiceHost + "/buy?id=" + id, null, Void.class);
    }
}
