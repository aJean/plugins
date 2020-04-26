import { Component } from 'react';
import { ApplyPluginsType } from 'umi';
import dva from 'dva';
// @ts-ignore
import createLoading from '{{{ dvaLoadingPkgPath }}}';
import { plugin, history } from '../core/umiExports';

let app:any = null;

function _onCreate() {
  // 这里就可以取到 src/app.ts 里面对于 dva 的 export
  const runtimeDva = plugin.applyPlugins({
    key: 'dva',
    type: ApplyPluginsType.modify,
    initialValue: {},
  });
  // 创建 dva 对象
  app = dva({
    history,
    {{{ ExtendDvaConfig }}}
    ...(runtimeDva.config || {}),
    // @ts-ignore
    ...(window.g_useSSR ? { initialState: window.g_initialData } : {}),
  });
  {{{ EnhanceApp }}}
  app.use(createLoading());
  // 注册的插件，比如 immer
  {{{ RegisterPlugins }}}
  (runtimeDva.plugins || []).forEach((plugin:any) => {
    app.use(plugin);
  });
  // 用户写的 model 都会在这里 add，src/modles
  {{{ RegisterModels }}}
  return app;
}

export function getApp() {
  return app;
}

export class _DvaContainer extends Component {
  constructor(props: any) {
    super(props);
    _onCreate();
  }

  componentWillUnmount() {
    let app = getApp();
    app._models.forEach((model:any) => {
      app.unmodel(model.namespace);
    });
    app._models = [];
    try {
      // 释放 app，for gc
      // immer 场景 app 是 read-only 的，这里 try catch 一下
      app = null;
    } catch(e) {
      console.error(e);
    }
  }

  render() {
    const app = getApp();
    app.router(() => this.props.children);
    return app.start()();
  }
}
