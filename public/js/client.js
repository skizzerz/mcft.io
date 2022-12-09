function Log(props) {
  const children = []
  if (typeof props.log == "object") {
    for (const v of Object.values(props.log)) {
      children.push(React.createElement('li', null, `${v}`));
    }
  }
  return React.createElement('ul', null, ...children);
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
    React.createElement(Log, { log: data?.log }),
    React.createElement('div', null, JSON.stringify(data)));
}

ReactDOM.render(
  React.createElement(App, { toWhat: 'world' }),
  document.getElementById('root')
);
