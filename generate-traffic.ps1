# Load Testing Script
# Run this to generate traffic for monitoring

Write-Host "Starting traffic generator..." -ForegroundColor Green
Write-Host "Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

$endpoints = @(
    "http://localhost:5000/",
    "http://localhost:5000/api/data",
    "http://localhost:5000/api/users",
    "http://localhost:5000/api/health"
)

$counter = 0

while ($true) {
    try {
        foreach ($endpoint in $endpoints) {
            $counter++
            $response = Invoke-WebRequest -Uri $endpoint -UseBasicParsing -TimeoutSec 5
            
            if ($response.StatusCode -eq 200) {
                Write-Host "[$counter] ✓ $endpoint - Status: $($response.StatusCode)" -ForegroundColor Green
            }
        }
        
        # Random delay between 1-3 seconds
        $delay = Get-Random -Minimum 1 -Maximum 3
        Start-Sleep -Seconds $delay
        
    } catch {
        Write-Host "[$counter] ✗ Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}
