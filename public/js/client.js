const ServerStartTime = "Sep 18 2022 00:06:57 GMT-0700";

function tickToDate(tick) {
  const d = new Date("Sep 18 2022 00:06:57 GMT-0700");
  d.setSeconds(tick + 57);
  return d;
}

function Log(props) {
  const children = []
  if (typeof props.log == "object") {
    for (const v of Object.values(props.log)) {
      children.push(React.createElement('li', null, `${v}`));
    }
  }
  return React.createElement('ul', null, ...children);
}

function MapDisplay({ data }) {
  const [filter, setFilter] = React.useState('')
  const children = []
  var x = 0;
  var y = 0;
  if (typeof data == "object") {
    const keys = Object.keys(data).sort();
    const lowerFilter = filter.toLowerCase();
    for (const v of keys) {
      if (lowerFilter.length == 0 || v.toLowerCase().indexOf(lowerFilter) != -1) {
        children.push(React.createElement('li', null, `${v} - ${data[v]}`));
        x++;
      }
    }
    y = keys.length;
  }
  return React.createElement('div', null,
    'Filter: ',
    React.createElement('input', { type: 'text', value: filter, onChange: (e) => setFilter(e.target.value) }),
    `${x} of ${y} items displayed`,
    React.createElement('ul', null, ...children));
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

function Chart({ dataY, dataX, useDerivative, scaleDataY, useSmooth }) {
  const width = 700;
  const height = 350;
  const refSVG = React.useRef();
  const refG = React.useRef();
  const refAxisX = React.useRef();
  const refAxisY = React.useRef();
  const refPath = React.useRef();
  const refTransform = React.useRef();

  React.useLayoutEffect(() => {
    if (Array.isArray(dataX) && Array.isArray(dataY)) {
      const defined = (d, i) => !isNaN(dataX[i]) && !isNaN(dataY[i]) && dataX[i] !== null && dataY[i] !== null;
      var I = d3.range(dataX.length);
      const D = d3.map(I, defined);
      I = I.filter(i => D[i]).sort((a, b) => +dataX[a] - +dataX[b]);

      dataY = I.map(i => +dataY[i] * +scaleDataY)
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
        dataY = applyFIR(dataY, [0.05, 0.1, 0.15, 0.2, 0.2, 0.15, 0.1, 0.05]);
        dataX = applyFIR(dataX, [0.05, 0.1, 0.15, 0.2, 0.2, 0.15, 0.1, 0.05]);
      }
      I = I.filter(i => !isNaN(dataY[i]) && !isNaN(dataX[i]))

      const yScale = d3.scaleLinear()
        .domain(!useDerivative ? [0, d3.max(dataY)] : [Math.min(0, d3.min(dataY)), Math.max(0, d3.max(dataY))])
        .range([height - 40, 20])

      const xExtent = d3.extent(dataX);

      const xScaleTime = d3.scaleTime()
        .domain([tickToDate(xExtent[0]), tickToDate(xExtent[1])])
        .range([30, width - 30])
      const xScaleLinear = d3.scaleTime()
        .domain(xExtent)
        .range([30, width - 30])

      const xAxis = d3.axisBottom(xScaleTime).ticks(width / 80).tickSizeOuter(0);
      const yAxis = d3.axisLeft(yScale).ticks(height / 40);
      const line = d3.line()
        .curve(d3.curveLinear)
        .x(i => xScaleLinear(dataX[i]))
        .y(i => yScale(dataY[i]));

      let zoom = d3.zoom()
        .on('zoom', handleZoom)
        .scaleExtent([1, 20])
        .translateExtent([[0, 0], [width, height]]);
      d3.select(refSVG.current)
        .attr("viewBox", [0, 0, width, height])
        .call(zoom);
      d3.select(refAxisX.current).attr("transform", `translate(0,${height - 40})`).call(xAxis);
      d3.select(refAxisY.current).attr("transform", `translate(30, 0)`).call(yAxis);

      function handleZoom({ transform }) {
        refTransform.current = transform
        // d3.select(refG.current)
        //   .attr('transform', `translate(${transform.x}, 0) scale(${transform.k}, 1)`);
        const newScaleX = transform.rescaleX(xScaleLinear);
        xAxis.scale(transform.rescaleX(xScaleTime));
        d3.select(refAxisX.current).call(xAxis);
        d3.select(refPath.current)
          .attr("d", line.x(i => newScaleX(dataX[i]))(I));
      }

      d3.select(refPath.current).attr("d", line(I))

      if (refTransform.current) { handleZoom({ transform: refTransform.current }); }
    }
  }, [dataY, dataX, width, height, useDerivative, useSmooth, scaleDataY])

  return React.createElement('svg', { class: 'chart', width, height, ref: refSVG },
    React.createElement('g', { ref: refAxisX }),
    React.createElement('g', { ref: refAxisY }),
    React.createElement('g', { ref: refG },
      React.createElement('path', { ref: refPath, fill: 'none', stroke: 'black' }))
  );
}

function CraftingMonitor({ crafting }) {
  if (!crafting) return;
  return React.createElement('ul', {},
    ...Object.keys(crafting).sort().map((k) => {
      const v = crafting[k];
      if (v.isBusy) {
        const making = v.finalOutput ? `${v.finalOutput.size}x ${v.finalOutput.label}` : 'unknown';
        return React.createElement('li', {}, `#${k} making ${making}`,
          React.createElement('ul', {}, ...Object.keys(v.activeItems).map((k) => {
            const w = v.activeItems[k];
            return React.createElement('li', {}, `Active: ${w.size}x ${w.label}`);
          }), ...Object.keys(v.pendingItems).map((k) => {
            const w = v.pendingItems[k];
            return React.createElement('li', {}, `Pending: ${w.size}x ${w.label}`);
          }), ...Object.keys(v.storedItems).map((k) => {
            const w = v.storedItems[k];
            return React.createElement('li', {}, `Stored: ${w.size}x ${w.label}`);
          }))
        )
      } else {
        return React.createElement('li', {}, `#${k} Inactive`)
      }
    })
  )
}

function ComboBox({ options, state }) {
  const [selected, setSelected] = state;
  const els = options.map((n) => React.createElement('option', { value: n }, n));
  return React.createElement('select', {
    onChange: (x) => { setSelected(x.target.value); },
    value: selected
  }, els);
}

function CheckBox({ state }) {
  const [checked, setChecked] = state
  return React.createElement('input', { type: 'checkbox', checked, onChange: e => setChecked(e.target.checked) })
}

function AnyChart({ charts }) {
  const chartState = React.useState(null);
  const smoothState = React.useState(false);
  const filterState = React.useState('raw');
  if (!charts) return React.createElement('div');

  const keys = Object.keys(charts).sort();
  if (chartState[0] == null) chartState[0] = keys[0]

  const useDerivative = filterState[0] != 'raw';
  const scaleDataY = filterState[0] == 'per tick' ? 1.0 / 20 : 1;

  return React.createElement('div', null,
    React.createElement(ComboBox, { options: keys, state: chartState }),
    React.createElement(ComboBox, { options: ['raw', 'per second', 'per tick'], state: filterState }),
    React.createElement('label', null,
      'Smooth:',
      React.createElement(CheckBox, { state: smoothState })),
    React.createElement(Chart, {
      dataY: charts[chartState[0]],
      dataX: charts.tick,
      useDerivative, scaleDataY,
      useSmooth: smoothState[0],
    })
  );
}

function reloadFile(uri, isJson) {
  const [data, setData] = React.useState(null);
  const [status, setStatus] = React.useState("init");
  const timeout = React.useRef(true);

  const updateData = async (controller) => {
    const signal = controller.signal;
    setStatus("fetching");
    const res = await fetch(uri, { signal });
    try {
      if (res.status != 200) {
        setStatus(res.status);
      } else {
        if (isJson) {
          setData(await res.json());
        } else {
          setData(await res.text());
        }
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
  return [data, status]
}

function jsonl_to_charts(jsonl) {
  if (!jsonl) return null;
  const lines = jsonl.split('\n')
    .map((line) => { try { return JSON.parse(line); } catch { return null; } })
    .filter((doc) => doc != null)
  const ret = {}
  for (const i in lines) {
    const line = lines[i];
    for (const k in line) {
      const v = line[k];
      if (!(k in ret)) { ret[k] = new Array(lines.length).fill(null); }
      ret[k][i] = v;
    }
  }
  return ret;
}

function Collapsable({ label, children }) {
  return React.createElement('div', { class: 'collapsible' },
    React.createElement('label', null,
      label,
      React.createElement('input', { type: 'checkbox' })),
    React.createElement('div', { class: 'collapse-content' }, ...children)
  );
}

function App() {
  const [data, status] = reloadFile("/reddisk/output.json", true);
  const [data2, status2] = reloadFile("/reddisk/charts.jsonl", false);

  return React.createElement('div', null, `Status: ${status}`,
    React.createElement('section', { id: 'charts' },
      React.createElement('h2', null, React.createElement('a', { href: '#charts', class: 'section-link' }), 'Charts'),
      React.createElement(AnyChart, { charts: data?.charts?.d }),
      React.createElement(AnyChart, { charts: jsonl_to_charts(data2) })),
    React.createElement('section', { id: 'items' },
      React.createElement('h2', null, React.createElement('a', { href: '#items', class: 'section-link' }), 'Items'),
      React.createElement(MapDisplay, { data: data?.memon?.items })),
    React.createElement('section', { id: 'crafting' },
      React.createElement('h2', null, React.createElement('a', { href: '#crafting', class: 'section-link' }), 'Crafting'),
      React.createElement(CraftingMonitor, { crafting: data?.memon?.crafting })),
    React.createElement('section', { id: 'log' },
      React.createElement('h2', null, React.createElement('a', { href: '#log', class: 'section-link' }), 'Log'),
      React.createElement(Log, { log: data?.log })),
    React.createElement('section', { id: 'raw-data' },
      React.createElement('h2', null, React.createElement('a', { href: '#log', class: 'section-link' }), 'Raw Data'),
      React.createElement(Collapsable, { label: 'Visible:', children: [JSON.stringify(data)] }))
  );
}

ReactDOM.render(
  React.createElement(App),
  document.getElementById('root')
);
