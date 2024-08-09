import globals from "globals";
import pluginJs from "@eslint/js";
import pluginReact from "eslint-plugin-react";


export default [
  { files: ["**/*.{js,mjs,cjs,jsx}"] },
  {
    files: ["public/**/*.js"],
    languageOptions: {
      ecmaVersion: 'latest',
      sourceType: "module",
      parserOptions: {
        ecmaFeatures: {
          jsx: true,
        },
      },
    },
    rules: {
      "react/jsx-uses-vars": "error",
      "react/jsx-uses-react": "error",
    },
  },
  { languageOptions: { globals: { ...globals.browser, ...globals.node, React: "writable", d3: "writable", ReactDOM: "writable" } } },
  pluginJs.configs.recommended,
  pluginReact.configs.flat.recommended,
  {
    rules: {
      'react/react-in-jsx-scope': 'off', // Disable this rule if using React 17+
      "react/prop-types": "off",
    },
  },
];