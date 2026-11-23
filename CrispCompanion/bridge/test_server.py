from types import SimpleNamespace
from server import normalize_status

def test_offline_does_not_fake_readings():
    state = SimpleNamespace(connection_status="offline", is_cooking=True,
                            cook_last_time=850, cook_set_temp=380, cook_mode="Air Fry",
                            cook_status="cooking")
    result = normalize_status(SimpleNamespace(state=state))
    assert result["connected"] is False
    assert result["cooking"] is False
    assert result["temperature_f"] is None
    assert result["minutes_remaining"] is None

def test_remaining_seconds_rounded_to_minutes():
    state = SimpleNamespace(connection_status="online", is_cooking=True,
                            cook_last_time=61, cook_set_temp=380, cook_mode="Air Fry",
                            cook_status="cooking")
    result = normalize_status(SimpleNamespace(state=state))
    assert result["connected"] is True
    assert result["minutes_remaining"] == 2
