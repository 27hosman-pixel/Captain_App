# Measurement Unit Integration Guide

The measurement unit preference is now saved and ready to use throughout your app. Here's how to integrate it:

## Quick Start

### 1. Read the User's Preference

Add this to any view where you need to display distances:

```swift
@AppStorage("measurement_unit") private var measurementUnitRaw: String = MeasurementUnit.imperial.rawValue

var measurementUnit: MeasurementUnit {
    MeasurementUnit(rawValue: measurementUnitRaw) ?? .imperial
}
```

### 2. Convert and Display Distances

Create a helper function in your view or a utility class:

```swift
func formatDistance(_ meters: Double) -> String {
    switch measurementUnit {
    case .imperial:
        let miles = meters / 1609.34
        return String(format: "%.2f mi", miles)
    case .metric:
        let kilometers = meters / 1000
        return String(format: "%.2f km", kilometers)
    }
}
```

### 3. Example Usage in Session Details

```swift
// In your session detail view
let distanceInMeters: Double = 5000 // Store all distances in meters

Text("Distance: \(formatDistance(distanceInMeters))")
```

## Best Practices

### Store Everything in Meters
Always store distances in meters in your data model. This makes it easy to:
- Convert to any unit for display
- Perform calculations consistently
- Support future unit additions

### Create a Utility Class

Consider creating a shared utility for distance formatting:

```swift
class DistanceFormatter {
    private var measurementUnit: MeasurementUnit
    
    init(measurementUnit: MeasurementUnit) {
        self.measurementUnit = measurementUnit
    }
    
    func format(_ meters: Double) -> String {
        switch measurementUnit {
        case .imperial:
            let miles = meters / 1609.34
            return String(format: "%.2f mi", miles)
        case .metric:
            let kilometers = meters / 1000
            return String(format: "%.2f km", kilometers)
        }
    }
    
    func formatShort(_ meters: Double) -> String {
        switch measurementUnit {
        case .imperial:
            let miles = meters / 1609.34
            if miles < 0.1 {
                let feet = meters * 3.28084
                return String(format: "%.0f ft", feet)
            }
            return String(format: "%.1f mi", miles)
        case .metric:
            let kilometers = meters / 1000
            if kilometers < 0.1 {
                return String(format: "%.0f m", meters)
            }
            return String(format: "%.1f km", kilometers)
        }
    }
    
    func unitLabel() -> String {
        measurementUnit.rawValue
    }
}
```

### Use Swift's Measurement API (Alternative)

For more advanced needs, consider using Swift's built-in `Measurement` type:

```swift
import Foundation

func formatDistance(_ meters: Double) -> String {
    let distance = Measurement(value: meters, unit: UnitLength.meters)
    
    let formatter = MeasurementFormatter()
    formatter.unitStyle = .medium
    formatter.numberFormatter.maximumFractionDigits = 2
    
    switch measurementUnit {
    case .imperial:
        return formatter.string(from: distance.converted(to: .miles))
    case .metric:
        return formatter.string(from: distance.converted(to: .kilometers))
    }
}
```

## Integration Points in Your App

Update these areas to use the measurement preference:

### Session Logging
- **LogPracticeView**: Distance input and display
- **LogGameView**: Distance input and display  
- **LogWorkoutView**: Distance input and display

### Session Display
- **HomeView**: Session cards showing distance
- **ProfileView**: Session feed with distances
- **SessionDetailView**: Detailed distance information

### Statistics
- **StatisticsView**: All distance-based metrics
- **Charts**: Distance over time graphs
- **Summaries**: Total distance, average distance, etc.

### Input Fields

When getting distance input from users, you might want to:

1. Show the input field in their preferred unit
2. Convert to meters before saving
3. Add a unit label to the input field

```swift
@State private var distanceInput: String = ""

TextField("Distance", text: $distanceInput)
    .keyboardType(.decimalPad)
    .overlay(alignment: .trailing) {
        Text(measurementUnit.rawValue)
            .foregroundColor(.secondary)
            .padding(.trailing, 8)
    }

// When saving:
func saveDistance() {
    guard let value = Double(distanceInput) else { return }
    
    let meters: Double = switch measurementUnit {
    case .imperial: value * 1609.34 // miles to meters
    case .metric: value * 1000 // kilometers to meters
    }
    
    // Save 'meters' to your session data
}
```

## Conversion Reference

### Miles to Meters
```swift
let meters = miles * 1609.34
```

### Kilometers to Meters
```swift
let meters = kilometers * 1000
```

### Meters to Miles
```swift
let miles = meters / 1609.34
```

### Meters to Kilometers
```swift
let kilometers = meters / 1000
```

### Feet to Meters
```swift
let meters = feet / 3.28084
```

### Meters to Feet
```swift
let feet = meters * 3.28084
```

## Example: Complete Session Card

```swift
struct SessionCardView: View {
    let session: SessionData
    @AppStorage("measurement_unit") private var measurementUnitRaw: String = MeasurementUnit.imperial.rawValue
    
    var measurementUnit: MeasurementUnit {
        MeasurementUnit(rawValue: measurementUnitRaw) ?? .imperial
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(session.title)
                .font(.headline)
            
            if let distanceMeters = session.details["distance_meters"],
               let meters = Double(distanceMeters) {
                HStack {
                    Image(systemName: "figure.run")
                    Text(formatDistance(meters))
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
    }
    
    private func formatDistance(_ meters: Double) -> String {
        switch measurementUnit {
        case .imperial:
            let miles = meters / 1609.34
            return String(format: "%.2f mi", miles)
        case .metric:
            let kilometers = meters / 1000
            return String(format: "%.2f km", kilometers)
        }
    }
}
```

---

## Testing Tips

1. **Test Both Units**: Switch between Imperial and Metric in Settings and verify:
   - All distances update correctly
   - Calculations remain accurate
   - Input fields show correct units

2. **Edge Cases**: Test with:
   - Very small distances (< 0.1 km/mi)
   - Very large distances
   - Zero distance
   - Decimal values

3. **Persistence**: Verify the preference persists after:
   - App restart
   - Logging out and back in
   - Device restart

---

Your measurement unit setting is now ready to use! 🎯
