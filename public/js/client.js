function Log(props) {
  const children = []
  if (typeof props.log == "object") {
    for (const v of Object.values(props.log)) {
      children.push(React.createElement('li', null, `${v}`));
    }
  }
  return React.createElement('ul', null, ...children);
}

function Chart({dataY, dataX}) {
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
      const yScale = d3.scaleLinear()
        .domain([0, d3.max(dataY)])
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
  }, [dataY, dataX, width, height])

  return React.createElement('svg', {width: '100%', height: '350px', ref: refSVG},
    React.createElement('g', {ref: refAxisX}),
    React.createElement('g', {ref: refAxisY}),
    React.createElement('path', {ref: refPath})
  );
}

function AnyChart({charts}) {
  const ch = charts?.d
  const [selected, setSelected] = React.useState(null);
  const ref = React.useRef();
  if (!ch) return React.createElement('div');

  const keys = Object.keys(ch)
  const options = keys.map((n) => React.createElement('option', {value: n}, n))

  return React.createElement('div', null,
    React.createElement('select', {onChange: (x) => { setSelected(x.target.value); console.log(x.target.value); }, value: selected, ref: ref}, options),
    React.createElement(Chart, {dataY: ch[selected], dataX: ch.tick})
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
