using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace pricing.Controllers;

[Route("[controller]")]
[ApiController]
public class PriceController : ControllerBase
{
    [HttpGet(Name = "GetPrice")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public ActionResult<PriceResult> Get([FromQuery] int id)
    {
        return GetPriceFromDb(id);
    }

    private PriceResult GetPriceFromDb(int id)
    {
        Console.WriteLine($"GetPriceFromDb thread: {System.Threading.Thread.CurrentThread.Name} price is: {id}");

        // Random double between 1 and 50
        Random random = new Random();
        double price = random.NextDouble() * 50 + 1;

        // Round to 2 decimal places
        price = Math.Round(price * 100.0) / 100.0;

        return new PriceResult(id, price);
    }
}

public class PriceResult
{
    public int Id { get; set; }
    public double Price { get; set; }

    public PriceResult(int id, double price)
    {
        Id = id;
        Price = price;
    }
}