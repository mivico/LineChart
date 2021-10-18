//
//  LineChartView.swift
//
//  Created by Mivic Ollennu.
//

import SwiftUI

struct LineChartView: View {
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
    @State private var animationProgress: CGFloat = 0
    
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
    var body: some View {
        GeometryReader { geometry in
            HStack {
                VStack {
                    GeometryReader { geometry in
                        ZStack {
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
                            /*
                            VStack {
                                HStack {
                                    VStack {
                                        /*
                                        HStack {
                                            Text("£\(String(format: "%.2f", getYLabel(xPos: self.viewState.width, geometrySize: geometry.size)))")
                                                .font(.largeTitle)
                                                .fontWeight(.bold)
                                            Spacer()
                                        }
                                        */
                                        /*
                                        HStack {
                                            Text("\(convertXPosToLabel(xPos: self.viewState.width, geometrySize: geometry.size))")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                        }
                                        */
                                        HStack {
                                            Text("\(convertXPosToLabel(xPos: self.viewState.width, geometrySize: geometry.size))")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                        }
                                    }
                                    Spacer()
                                }
                                Spacer()
                            }
                            .opacity(showPicker ? 1 : 0)
                            */
                            
                            Color.white
                                .opacity(0.001)
                                .gesture(DragGesture()
                                            .onChanged { value in
                                    DispatchQueue.global(qos: .userInteractive).async {
                                        //self.viewState = value.translation
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
                        }
                    }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                withAnimation(.easeIn(duration: 2)) {
                                    animationProgress = 1.0
                                }
                            }
                        }
                    //Axis
                }
            }
        }
    }
}

struct LineChartView_Previews: PreviewProvider {
    static var previews: some View {
        LineChartView(data: .constant([LineChartData(id: "1", xLabel: 0, yLabel: 10), LineChartData(id: "2", xLabel: 30, yLabel: 23), LineChartData(id: "3", xLabel: 60, yLabel: 43), LineChartData(id: "4", xLabel: 90, yLabel: 54), LineChartData(id: "5", xLabel: 120, yLabel: 30), LineChartData(id: "6", xLabel: 150, yLabel: 20), ]))
    }
}

extension LineChartView {
    
    private func getYLabel(xPos: Double, geometrySize: CGSize) -> Double {
        let xLabel = convertXPosToLabel(xPos: xPos, geometrySize: geometrySize)
        var result = Double(0)
        for index in 1..<self.data.count {
            let lowerBound = self.data[index - 1].xLabel
            let upperBound = self.data[index].xLabel
            if ((xLabel <= upperBound) && (xLabel >= lowerBound)) {
                //Let us find the interp fraction
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
