import httpx
import json
from datetime import datetime, timedelta

BASE_URL = "http://127.0.0.1:8000"

def run_integration_tests():
    print("🚀 Starting Freezer Penguin Backend Integration Tests...\n")
    
    # Generate valid test dates mathematically
    today_str = datetime.now().date().isoformat()
    future_date_str = (datetime.now() + timedelta(days=30)).date().isoformat()
    
    # =========================================================================
    # TEST CASE 1: Send Perfect Data (A Real UPC Code to trigger Open Food Facts)
    # =========================================================================
    print("📋 Test 1: Sending a valid item (Cache-Miss Trigger)...")
    valid_payload = {
        "user_id": 1,
        "quantity": 2,
        "expiration_date": future_date_str,
        "upc": "041196910719", # Real UPC string (e.g., standard pantry item)
        "location_id": 1,
        "unit_id": 1
    }
    
    response = httpx.post(f"{BASE_URL}/inventory/add", json=valid_payload, timeout=10.0)
    print(f"   Status Code: {response.status_code}")
    print(f"   Response: {response.json()}\n")
    
    # =========================================================================
    # TEST CASE 2: Validation Failure (Negative Quantity)
    # =========================================================================
    print("🛡️ Test 2: Verifying Pydantic catches a negative quantity (quantity: -5)...")
    bad_qty_payload = valid_payload.copy()
    bad_qty_payload["quantity"] = -5
    
    response = httpx.post(f"{BASE_URL}/inventory/add", json=bad_qty_payload)
    print(f"   Status Code: {response.status_code} (Should be 422 Unprocessable Entity)")
    if response.status_code == 422:
        print("   ✅ Success: Pydantic successfully blocked the negative quantity!")
    else:
        print("   ❌ Failure: Server allowed a negative quantity!")
    print(f"   Error Detail: {response.json().get('detail')[0].get('msg')}\n")

    # =========================================================================
    # TEST CASE 3: Validation Failure (Sci-Fi Expiration Date)
    # =========================================================================
    print("🛡️ Test 3: Verifying Custom Validator catches a sci-fi year (year 9026)...")
    bad_date_payload = valid_payload.copy()
    bad_date_payload["expiration_date"] = "9026-12-25"
    
    response = httpx.post(f"{BASE_URL}/inventory/add", json=bad_date_payload)
    print(f"   Status Code: {response.status_code} (Should be 422 Unprocessable Entity)")
    if response.status_code == 422:
        print("   ✅ Success: Custom field validator successfully blocked the year 9026!")
    else:
        print("   ❌ Failure: Server allowed an unrealistic expiration date!")
    print(f"   Error Detail: {response.json().get('detail')[0].get('msg')}\n")

    # =========================================================================
    # TEST CASE 4: Verify the Dashboard Query Matrices
    # =========================================================================
    print("📊 Test 4: Verifying GET Dashboard Matrices with SQL CASE statements...")
    get_response = httpx.get(f"{BASE_URL}/inventory/expiring/1?limit=5")
    print(f"   Status Code: {get_response.status_code}")
    
    if get_response.status_code == 200:
        data = get_response.json()
        print(f"   User Email Tracked: {data.get('email')}")
        print(f"   Total Active Alerts: {data.get('total_alerts')}")
        print("   Processed SQL Rows:")
        for item in data.get("items")[:2]: # Show up to first two
            print(f"     - {item.get('product_name')} | Status: {item.get('status_urgency')} | Days: {item.get('days_remaining')}")
    print("\n🏁 Integration Testing Suite Complete.")

if __name__ == "__main__":
    run_integration_tests()