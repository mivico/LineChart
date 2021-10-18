# Line Chart
 
Goal: Create an interactive line chart which stays updated by providing a binding to a dataset.

Firstly, we need a new datatype. We can call it LineChartData consisting of 3 attributes:

```swift
struct LineChartData : Identifiable {
    var id: String
    var xLabel: Double
    var yLabel: Double
}
```
With this, we have defined a standard method of structuring our line chart data. Our line chart will take an array of this datatype and construct it into a line chart.

Next, we need to define and initialise a few variables for the line chart.

```swift
    @Binding var data: [LineChartData]
    @State var viewState = CGSize.zero
    @State var showPicker = false
    @State var showLegend = true
    private var maxY: Double
    private var minY: Double
    private var maxX: Double
    private var minX: Double
    private var xAxis: Double
    private var yAxis: Double
    private var lineColor: Color
    
    init(data: Binding<[LineChartData]>) {
        self._data = data
        self.maxY = 0
        self.minY = 0
        self.maxX = 0
        self.minX = 0
        self.xAxis = 0
        self.yAxis = 0
        self.lineColor = .white
        if(data.count > 0) {
            self.maxY = self.data.sorted {
                $0.yLabel > $1.yLabel
            }[0].yLabel
            self.minY = self.data.sorted {
                $0.yLabel < $1.yLabel
            }[0].yLabel
            self.maxX = self.data.sorted {
                $0.xLabel > $1.xLabel
            }[0].xLabel
            self.minX = self.data.sorted {
                $0.xLabel < $1.xLabel
            }[0].xLabel
            if (self.data.count > 1) {
                let deltaY = self.data[self.data.count-1].yLabel - self.data[self.data.count-2].yLabel
                if (deltaY > 0) {
                    lineColor = Color.green
                } else if (deltaY == 0) {
                    lineColor = Color.black
                } else if (deltaY < 0) {
                    lineColor = Color.red
                } else {
                    lineColor = Color.gray
                }
            } else {
                lineColor = Color.gray
            }
            self.xAxis = maxX - minX
            self.yAxis = maxY - minY
        }
    }
```

With these variables in place, we can begin to construct the line chart.

```swift
GeometryReader { geometry in          
    Path { path in
        for index in data.indices {
            let xPosition = CGFloat((data[index].xLabel - minX) / xAxis) * geometry.size.width
            let yPosition = (1 - CGFloat((data[index].yLabel - minY) / yAxis)) * geometry.size.height
            if (index == 0) {
                path.move(to: CGPoint(x: xPosition, y: yPosition))
            }
            path.addLine(to: CGPoint(x: xPosition, y: yPosition))
        }
    }
    .trim(from: 0.0, to: animationProgress)
    .stroke(lineColor, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
    .shadow(color: lineColor.opacity(0.3), radius: 10, x: 0, y: 10)
}
```

This is essentially the main part of the line chart. Now we move onto the interactive section of the line chart. Firstly, we require a transparent layer on top of the line chart to allow for the interactivity. To do this, we wrap the line chart into a ZStack and put a white rectangle over the chart with an opacity of 0.001. Please note, this number needs to be greater than 0 to be interactive.

Our goal for the interactivity is to have a circle on top of the line chart which follows the position of your finger and reveals information about the chart. We do this by applying a drag gesture onto the transparent white layer.

```swift
    Color.white
    .opacity(0.001)
    .gesture(DragGesture()
    .onChanged { value in
        DispatchQueue.global(qos: .userInteractive).async {
            self.showPicker = true
            if((value.location.x < geometry.size.width) && (value.location.x > 0)) {
            self.viewState.width = value.location.x
            }
        }
    }
    .onEnded { value in
        DispatchQueue.global(qos: .userInteractive).async {
            withAnimation(.spring()) {
                self.showPicker = false
            }
        }
    }
    )
```

Contraints have been placed onto the x value so that we are only reading data from within the chart. Now we need to add the circle on top of the line chart. We can easily add the circle and make it follow our finger on the x axis but the y axis takes a bit more work. To make the picker circle follow the chart on the y axis, we need to take advantage of interpolation. We need to create a function as such:

```swift
extension LineChartView {
    
    private func getYLabel(xPos: Double, geometrySize: CGSize) -> Double {
        let xLabel = convertXPosToLabel(xPos: xPos, geometrySize: geometrySize)
        var result = Double(0)
        for index in 1..<self.data.count {
            let lowerBound = self.data[index - 1].xLabel
            let upperBound = self.data[index].xLabel
            if ((xLabel <= upperBound) && (xLabel >= lowerBound)) {
                let interpFrac = (upperBound -  lowerBound) / (xLabel - lowerBound)
                result = self.data[index - 1].yLabel + (self.data[index].yLabel - self.data[index - 1].yLabel) / interpFrac
            }
        }
        return result
    }
    
    private func getYPos(xPos: Double, geometrySize: CGSize) -> Double {
        let yLabel = getYLabel(xPos: xPos, geometrySize: geometrySize)
        return (1 - CGFloat((yLabel - minY) / yAxis)) * geometrySize.height
    }
    
    private func convertXPosToLabel(xPos: Double, geometrySize: CGSize) -> Double {
        return ((xAxis*xPos) / geometrySize.width) + minX
    }
    
    private func convertYPosToLabel(yPos: Double, geometrySize: CGSize) -> Double {
        return ((yAxis*yPos) / geometrySize.height) + minY
    }
}
```

This function uses the x position provided by the geometry reader and gives us a y position corresponding to it. As a result, we are able to interpolate numbers between each line and get the raw values for both the x and y axis.

```swift
    Rectangle()
    .fill(
        LinearGradient(gradient: Gradient(colors: [Color(#colorLiteral(red: 0.9568627451, green: 0.3607843137, blue: 0.262745098, alpha: 1)).opacity(0.5), Color(#colorLiteral(red: 0.9215686275, green: 0.2, blue: 0.2862745098, alpha: 1)), Color(#colorLiteral(red: 0.9568627451, green: 0.3607843137, blue: 0.262745098, alpha: 1)).opacity(0.5)]), startPoint: .top, endPoint: .bottom))
    .frame(width: 2, height: geometry.size.height)
    .position(x: self.viewState.width, y: geometry.size.height / 2)
    .opacity(showPicker ? 1 : 0)

    Circle()
    .frame(width: 10, height: 10)
    .position(x: self.viewState.width, y: getYPos(xPos: self.viewState.width, geometrySize: geometry.size))
    .opacity(showPicker ? 1 : 0)
```

Now by adding this to the ZStack, we now have a visible picker for the line chart and a vertical line. From here, we can further customise the graph by showing the actual data when the drag gesture is started as we are now getting the x and y values from the convertXPosToLabel and convertYPosToLabel functions. These can be placed on top of the chart with a varying opacity based on when the drag gesture has started.

As an optional piece of this chart, I have added a function called makeLineChartCumulative which takes in an array of LineChartData and returns a cummulative array. This cummulative array could be passed into the argument rather than the normal array.

```swift
func makeLineChartCumulative(original: [LineChartData]) -> [LineChartData] {
    var result: [LineChartData] = []
    if(original.count > 0) {
    result.append(original[0])
    if(original.count > 1) {
    for index in 1...original.count - 1 {
        result.append(LineChartData(id: original[index].id, xLabel: original[index].xLabel, yLabel: original[index].yLabel + result[index - 1].yLabel))
    }
    }
    }
    return result
}
```
