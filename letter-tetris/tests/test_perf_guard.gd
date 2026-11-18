extends GutTest


func test_fast_device_stays_full_resolution() -> void:
	assert_eq(PerfGuard.next_step(0, 60.0), 0)
	assert_eq(PerfGuard.next_step(0, 120.0), 0)


func test_slow_device_steps_down_to_75() -> void:
	assert_eq(PerfGuard.next_step(0, 36.0), 1)


func test_still_slow_steps_down_to_60_then_stops() -> void:
	assert_eq(PerfGuard.next_step(1, 35.0), 2)
	assert_eq(PerfGuard.next_step(1, 45.0), 1, "über 40 bleibt es bei 75 %")
	assert_eq(PerfGuard.next_step(2, 20.0), 2, "nicht weiter als 60 %")
