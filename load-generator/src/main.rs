use reqwest;
use std::process;
use tokio::time::{sleep, Duration};
use rand::Rng;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let client = reqwest::Client::new();

    let frontend_service_host = std::env::var("FRONTEND_SERVICE_HOST")
        .unwrap_or("frontend:8080".to_string());
    let delay_seconds = std::env::var("LOAD_GENERATOR_DELAY_SECONDS")
        .unwrap_or("3".to_string())
        .parse::<u64>()
        .unwrap();
    let max_iterations = std::env::var("LOAD_GENERATOR_MAX_ITERATIONS")
        .unwrap_or("10".to_string())
        .parse::<i32>()
        .unwrap();

    let mut current_iteration = 0;

    loop {
        current_iteration += 1;
        println!("Iteration {} of {}", current_iteration, max_iterations);

        // Generate random ID between 1 and 100
        let random_id = rand::thread_rng().gen_range(1..=100);

        // Make POST request to the specified endpoint
        let response = client
            .post(format!("http://{}/buy?id={}", frontend_service_host, random_id))
            .send()
            .await?;

        println!("Response status: {} (ID: {})", response.status(), random_id);

        // Check if we've reached the maximum iterations
        if current_iteration >= max_iterations {
            println!("Reached maximum iterations. Exiting.");
            break;
        }

        // Wait before next iteration
        sleep(Duration::from_secs(delay_seconds)).await;
    }

    // Exit gracefully
    process::exit(0);
}
