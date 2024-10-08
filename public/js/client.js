const ServerStartTime = "Sep 18 2022 00:01:57 GMT-0700";

function tickToDate(tick) {
  const d = new Date(ServerStartTime);
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

/**
 * @typedef {object} ChartProps
 * @property {number[]} dataY
 * @property {number[]} dataX
 * @property {boolean} useDerivative
 * @property {number} scaleDataY
 * @property {boolean} useSmooth
 * @param {ChartProps} anon
 */
function Chart({ dataY, dataX, useDerivative, scaleDataY, useSmooth }) {
  const width = 700;
  const height = 350;
  /** @type {React.MutableRefObject<HTMLElement|undefined>} */
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

      // @ts-ignore
      const yExtent = !useDerivative ? [0, d3.max(dataY)] : [Math.min(0, d3.min(dataY)), Math.max(0, d3.max(dataY))]

      const yScale = d3.scaleLinear()
        // @ts-ignore
        .domain(yExtent)
        .range([height - 40, 20])

      // This uses SI prefixes, so we change "giga" to "billions" (thousands, millions, and trillions are
      // good with k, M, and T, respectively)
      const yFormat = y => d3.format(".3s")(y).replace("G", "B");
      const xExtent = d3.extent(dataX);

      const xScaleTime = d3.scaleTime()
        .domain([tickToDate(xExtent[0]), tickToDate(xExtent[1])])
        .range([50, width - 20])
      const xScaleLinear = d3.scaleTime()
        // @ts-ignore
        .domain(xExtent)
        .range([50, width - 20])

      const xAxis = d3.axisBottom(xScaleTime).ticks(width / 80).tickSizeOuter(0);
      const yAxis = d3.axisLeft(yScale).ticks(height / 40).tickFormat(yFormat);
      const line = d3.line()
        .curve(d3.curveLinear)
        // @ts-ignore
        .x(i => xScaleLinear(dataX[i]))
        // @ts-ignore
        .y(i => yScale(dataY[i]));

      /** @type {d3.ZoomBehavior<HTMLElement>} */
      // @ts-ignore
      let zoom = d3.zoom()
        .on('zoom', handleZoom)
        .scaleExtent([1, 20])
        .translateExtent([[0, 0], [width, height]]);
      if (refSVG.current) d3.select(refSVG.current)
        .attr("viewBox", [0, 0, width, height])
        .call(zoom);
      if (refAxisX.current) d3.select(refAxisX.current).attr("transform", `translate(0,${height - 40})`).call(xAxis);
      if (refAxisY.current) d3.select(refAxisY.current).attr("transform", `translate(50, 0)`).call(yAxis);

      function handleZoom({ transform }) {
        refTransform.current = transform
        // d3.select(refG.current)
        //   .attr('transform', `translate(${transform.x}, 0) scale(${transform.k}, 1)`);
        const newScaleX = transform.rescaleX(xScaleLinear);
        xAxis.scale(transform.rescaleX(xScaleTime));
        if (refAxisX.current) d3.select(refAxisX.current).call(xAxis);
        if (refPath.current) d3.select(refPath.current)
          .attr("d", line.x(i => newScaleX(dataX[i]))(I));
      }

      if (refPath.current) d3.select(refPath.current).attr("d", line(I))

      if (refTransform.current) { handleZoom({ transform: refTransform.current }); }
    }
  }, [dataY, dataX, width, height, useDerivative, useSmooth, scaleDataY])

  return React.createElement('svg', { className: 'chart', ref: refSVG },
    React.createElement('g', { ref: refAxisX }),
    React.createElement('g', { ref: refAxisY }),
    React.createElement('g', { ref: refG },
      React.createElement('path', { ref: refPath, fill: 'none', stroke: 'black' }))
  );
}

function CraftingMonitor({ crafting }) {
  if (!crafting) return;
  return React.createElement('ul', {},
    ...Object.keys(crafting).sort((a, b) =>
      `${crafting[a].name}#${a}`.localeCompare(`${crafting[b].name}#${b}`, undefined, { numeric: true })
    ).map((k) => {
      const v = crafting[k];
      if (v.isBusy) {
        const making = v.finalOutput ? `${v.finalOutput.size}x ${v.finalOutput.label}` : 'unknown';
        return React.createElement('li', {}, `${v.name}#${k} making ${making}`,
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
        return React.createElement('li', {}, `${v.name}#${k} Inactive`)
      }
    })
  )
}

function ComboBox({ options, state }) {
  const [selected, setSelected] = state;
  const els = options.map((n) => React.createElement('option', { key: n, value: n }, n));
  return React.createElement('select', {
    // @ts-ignore
    onChange: (x) => { setSelected(x.target.value); },
    value: selected
  }, els);
}

function CheckBox({ state }) {
  const [checked, setChecked] = state
  // @ts-ignore
  return React.createElement('input', { type: 'checkbox', checked, onChange: e => setChecked(e.target.checked) })
}

function AnyChart({ charts }) {
  const chartState = React.useState("");
  const smoothState = React.useState(false);
  const filterState = React.useState('raw');
  if (!charts) return React.createElement('div');

  const keys = Object.keys(charts).sort();
  if (chartState[0] == "") chartState[0] = keys[0]

  const useDerivative = filterState[0] != 'raw';
  const scaleDataY = filterState[0] == 'per tick' ? 1.0 / 20 : 1;

  return React.createElement('div', { className: 'anychart col-12 col-xxl-6' },
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

function AnyCharts({ charts }) {
  const [count, setCount] = React.useState(1);
  const children = [];
  for (var k = 0; k < count; ++k) {
    children.push(React.createElement(AnyChart, { charts }))
  }
  return React.createElement('div', null,
    React.createElement('button', { onClick: () => setCount((x) => x + 1) }, 'Add Chart'),
    React.createElement('button', { onClick: () => setCount((x) => Math.max(1, x - 1)) }, 'Remove Chart'),
    React.createElement('div', { className: 'd-flex flex-row row' }, ...children));
}

function reloadFile(uri, isJson, freq = 5000) {
  const [data, setData] = React.useState(isJson ? null : "");
  const [status, setStatus] = React.useState("init");

  React.useEffect(() => {
    const controller = new AbortController();
    const updateData = async () => {
      const signal = controller.signal;
      setStatus("fetching");
      const res = await fetch(uri, { signal });
      try {
        if (res.status != 200) {
          setStatus("" + res.status);
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
      if (!signal.aborted)
        timeout = setTimeout(updateData, freq)
    };
    let timeout = setTimeout(updateData, 0)
    return () => {
      controller.abort();
      clearTimeout(timeout);
    };
  }, [uri, isJson]);
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
  return React.createElement('div', { className: 'collapsible col' },
    React.createElement('label', null,
      label,
      React.createElement('input', { type: 'checkbox' })),
    React.createElement('div', { className: 'collapse-content' }, ...children)
  );
}

function NavItem({ href, text, icon, current }) {
  if (current == href) {
    return React.createElement('li', { className: 'nav-item' },
      React.createElement('a', { href, className: 'nav-link active' },
        React.createElement('svg', { className: 'bi pe-none me-2', width: 16, height: 16 },
          React.createElement('use', { href: icon })
        ),
        ` ${text}`
      )
    );
  } else {
    return React.createElement('li', {},
      React.createElement('a', { href, className: 'nav-link link-body-emphasis' },
        React.createElement('svg', { className: 'bi pe-none me-2', width: 16, height: 16 },
          React.createElement('use', { href: icon })
        ),
        ` ${text}`
      )
    );
  }
}

function SmallNavItem({ href, icon, current }) {
  if (current == href) {
    return React.createElement('li', { className: 'nav-item' },
      React.createElement('a', { href, className: 'nav-link active py-3 border-bottom rounded-0' },
        React.createElement('svg', { className: 'bi pe-none', width: 16, height: 16 },
          React.createElement('use', { href: icon })
        )
      )
    );
  } else {
    return React.createElement('li', {},
      React.createElement('a', { href, className: 'nav-link py-3 border-bottom rounded-0 link-body-emphasis' },
        React.createElement('svg', { className: 'bi pe-none', width: 16, height: 16 },
          React.createElement('use', { href: icon })
        )
      )
    );
  }
}

function NavList() {
  const [scrollPosition, setScrollPosition] = React.useState(0);

  React.useEffect(() => {
    const f = () => { setScrollPosition(window.scrollY); };
    window.addEventListener('scroll', f);
    return () => {
      window.removeEventListener('scroll', f);
    };
  }, []);

  const sections = [
    { href: '#charts-realtime', text: 'Charts (Realtime)', icon: '#speedometer2' },
    { href: '#charts-long', text: 'Charts (Long-Term)', icon: '#speedometer2' },
    { href: '#crafting', text: 'Crafting', icon: '#table' },
    { href: '#log', text: 'Logs', icon: '#table' },
    { href: '#textfiles', text: 'Text Files', icon: '#table' },
    { href: '#items', text: 'Items', icon: '#grid' },
    { href: '#raw-data', text: 'Raw Data', icon: '#table' },
  ]

  let current = sections[0].href;
  for (let i = sections.length; i > 1;) {
    --i
    const section = sections[i]
    const offtop = document.getElementById(section.href.substring(1))?.offsetTop
    if (offtop && offtop - 10 <= scrollPosition) {
      current = section.href
      break
    }
  }

  return React.createElement(React.Fragment, null,
    React.createElement('ul', { className: 'nav nav-pills flex-column mb-auto d-none d-md-flex' },
      ...sections.map((s) =>
        React.createElement(NavItem, { key: s.href, ...s, current })),
    ),
    React.createElement('ul', { className: 'nav nav-pills nav-flush flex-column mb-auto d-md-none d-flex text-center' },
      ...sections.map((s) =>
        React.createElement(SmallNavItem, { key: s.href, href: s.href, icon: s.icon, current })),
    ));
}

function Sidebar({ state, proxyState }) {
  return React.createElement('div', {
    className: 'sidebar d-flex flex-shrink-0 flex-column border border-right col-2 col-md-4 col-lg-3 col-xxl-2 px-0 px-md-3 pt-3 bg-body-tertiary',
    style: {}
  },
    React.createElement('div', { className: 'd-flex align-items-center mb-md-0' },
      React.createElement('span', { className: 'd-none d-md-inline fs-5' }, 'GTNH: Skizzerz Edition'),
      React.createElement('span', { className: 'd-md-none mx-auto fs-5' }, 'GTNH')
    ),
    React.createElement('hr'),
    React.createElement(NavList),
    React.createElement('hr'),
    React.createElement('div', {}, `Status: ${state}`,
      React.createElement('div', { style: { float: 'right' } },
        React.createElement(CheckBox, { state: proxyState }))),
  );
}

function App() {
  const proxyState = React.useState(false);
  const [data, status] = reloadFile((proxyState[0] ? '/fwd' : '') + "/reddisk/output.json", true);
  const [data2] = reloadFile((proxyState[0] ? '/fwd' : '') + "/reddisk/charts.jsonl", false);
  const [erl_network] = reloadFile("/erl/network.txt", false, 20000);
  const [erl_cpu_status] = reloadFile("/erl/cpu_status.txt", false);
  const [erl_gt_status] = reloadFile("/erl/gt_status.txt", false, 10000);

  return React.createElement('div', { className: 'row' },
    React.createElement(Sidebar, { state: status, proxyState }),
    React.createElement('main', { className: 'col-10 col-md-8 col-lg-9 px-md-4' },
      React.createElement('div', { className: 'b-example-divider b-example-vr' }),
      React.createElement('div', {},
        React.createElement('section', { id: 'charts-realtime' },
          React.createElement('h2', null, React.createElement('a', { href: '#charts-realtime', className: 'section-link' }), 'Charts (Realtime)'),
          React.createElement(AnyCharts, { charts: data?.charts?.d })),
        React.createElement('section', { id: 'charts-long' },
          React.createElement('h2', null, React.createElement('a', { href: '#charts-long', className: 'section-link' }), 'Charts (Long-Term)'),
          React.createElement(AnyCharts, { charts: jsonl_to_charts(data2) })),
        React.createElement('section', { id: 'crafting' },
          React.createElement('h2', null, React.createElement('a', { href: '#crafting', className: 'section-link' }), 'Crafting'),
          React.createElement(CraftingMonitor, { crafting: data?.memon?.crafting })),
        React.createElement('section', { id: 'log' },
          React.createElement('h2', null, React.createElement('a', { href: '#log', className: 'section-link' }), 'Log'),
          React.createElement(Log, { log: data?.log })),
        React.createElement('section', { id: 'textfiles' },
          React.createElement('h2', null, React.createElement('a', { href: '#textfiles', className: 'section-link' }), 'Text Files'),
          React.createElement('pre', {}, erl_network),
          React.createElement('pre', {}, erl_cpu_status),
          React.createElement('pre', {}, erl_gt_status)),
        React.createElement('section', { id: 'items' },
          React.createElement('h2', null, React.createElement('a', { href: '#items', className: 'section-link' }), 'Items'),
          React.createElement(MapDisplay, { data: data?.memon?.items })),
        React.createElement('section', { id: 'raw-data' },
          React.createElement('h2', null, React.createElement('a', { href: '#raw-data', className: 'section-link' }), 'Raw Data'),
          React.createElement(Collapsable, { label: 'Visible:' }, JSON.stringify(data)))
      )));
}

//@ts-ignore
const root = ReactDOM.createRoot(document.getElementById('root'))
root.render(React.createElement(App))
