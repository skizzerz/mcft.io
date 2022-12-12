function Log(props) {
  const children = []
  if (typeof props.log == "object") {
    for (const v of Object.values(props.log)) {
      children.push(React.createElement('li', null, `${v}`));
    }
  }
  return React.createElement('ul', null, ...children);
}

function applyFIR(data, kernel) {
  const revKernel = [...kernel].reverse();
  const ret = new Array(data.length).fill(NaN, 0, kernel.length - 1);
  for (var i = kernel.length - 1; i < data.length; ++i) {
    var v = 0;
    for (var k = 0; k < kernel.length; ++k) {
      v += +revKernel[k] * +data[i - k];
    }
    ret[i] = v;
  }
  return ret;
}

function Chart({ dataY, dataX, useDerivative, useSmooth }) {
  const width = 700;
  const height = 350;
  const refSVG = React.useRef();
  const refAxisX = React.useRef();
  const refAxisY = React.useRef();
  const refPath = React.useRef();

  React.useLayoutEffect(() => {
    if (Array.isArray(dataX) && Array.isArray(dataY)) {
      const defined = (d, i) => !isNaN(dataX[i]) && !isNaN(dataY[i]) && dataX[i] !== null && dataY[i] !== null;
      var I = d3.range(dataX.length);
      const D = d3.map(I, defined);
      I = I.filter(i => D[i]).sort((a, b) => +dataX[a] - +dataX[b]);

      dataY = I.map(i => +dataY[i])
      dataX = I.map(i => +dataX[i])
      I = d3.range(dataY.length)

      if (useDerivative) {
        const newDataY = new Array(dataY.length);
        newDataY[0] = NaN
        for (var i = 1; i < dataY.length; ++i) {
          const j = i - 1;
          const delta = dataX[i] - dataX[j];
          newDataY[i] = delta > 0 ? (dataY[i] - dataY[j]) / delta : NaN;
        }
        dataY = newDataY;
      }
      if (useSmooth) {
        const newDataY = applyFIR(dataY, [0.05, 0.1, 0.15, 0.2, 0.2, 0.15, 0.1, 0.05]);
        dataY = newDataY;
      }
      I = I.filter(i => !isNaN(dataY[i]))

      const yScale = d3.scaleLinear()
        .domain(!useDerivative ? [0, d3.max(dataY)] : [Math.min(0, d3.min(dataY)), Math.max(0, d3.max(dataY))])
        .range([height - 40, 20])

      const xScale = d3.scaleLinear()
        .domain(d3.extent(dataX))
        .range([30, width - 30])

      const xAxis = d3.axisBottom(xScale).ticks(width / 80).tickSizeOuter(0);
      const yAxis = d3.axisLeft(yScale).ticks(height / 40);
      const line = d3.line()
        .curve(d3.curveLinear)
        .x(i => xScale(dataX[i]))
        .y(i => yScale(dataY[i]));

      d3.select(refSVG.current).attr("viewBox", [0, 0, width, height]);
      d3.select(refAxisX.current).attr("transform", `translate(0,${height - 40})`).call(xAxis);
      d3.select(refAxisY.current).attr("transform", `translate(30, 0)`).call(yAxis);

      d3.select(refPath.current)
        .attr("fill", "none")
        .attr("stroke", "black")
        .attr("d", line(I))
    }
  }, [dataY, dataX, width, height, useDerivative, useSmooth])

  return React.createElement('svg', { width: '100%', height: '350px', ref: refSVG },
    React.createElement('g', { ref: refAxisX }),
    React.createElement('g', { ref: refAxisY }),
    React.createElement('path', { ref: refPath })
  );
}

function ComboBox({ options, state }) {
  const [selected, setSelected] = state;
  const els = options.map((n) => React.createElement('option', { value: n }, n));
  return React.createElement('select', {
    onChange: (x) => { setSelected(x.target.value); },
    value: selected
  }, els);
}

function AnyChart({ charts }) {
  const ch = charts?.d
  const selectChart = React.useState(null);
  const selectFilter = React.useState('none');
  if (!ch) return React.createElement('div');

  const useDerivative = selectFilter[0] && { none: false, smooth: false, derivative: true, smoothDerivative: true }[selectFilter[0]];
  const useSmooth = selectFilter[0] && { none: false, smooth: true, derivative: false, smoothDerivative: true }[selectFilter[0]];

  return React.createElement('div', null,
    React.createElement(ComboBox, { options: Object.keys(ch).sort(), state: selectChart }),
    React.createElement(ComboBox, { options: ['none', 'smooth', 'derivative', 'smoothDerivative'], state: selectFilter }),
    React.createElement(Chart, { dataY: ch[selectChart[0]], dataX: ch.tick, useDerivative, useSmooth })
  );
}

function App(props) {
  const [data, setData] = React.useState(null);
  const [status, setStatus] = React.useState("init");
  const timeout = React.useRef(true);

  const updateData = async (controller) => {
    const signal = controller.signal;
    setStatus("fetching");
    const res = await fetch("/reddisk/output.json", { signal });
    try {
      if (res.status != 200) {
        setStatus(res.status);
      } else {
        const json = await res.json();
        setData(json);
        setStatus("loaded");
      }
    } catch (e) {
      setStatus(`${e}`)
    }
    if (timeout.current) {
      timeout.current = setTimeout(() => updateData(controller), 5000)
    }
  };
  React.useEffect(() => {
    const controller = new AbortController();
    updateData(controller);
    return () => {
      if (timeout.current) clearTimeout(timeout.current);
      controller.abort();
    };
  }, []);
  return React.createElement('div', null, `Hello ${props.toWhat} - ${status}`,
    React.createElement(AnyChart, { charts: data?.charts }),
    React.createElement(Log, { log: data?.log }),
    React.createElement('div', null, JSON.stringify(data)));
}

ReactDOM.render(
  React.createElement(App, { toWhat: 'world' }),
  document.getElementById('root')
);
