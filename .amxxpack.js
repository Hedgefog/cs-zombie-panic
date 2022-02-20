const path = require('path');
const os = require('os');

const compilerExecutable = os.platform() === 'win32' ? 'amxxpc.exe' : 'amxxpc';

module.exports = {
  compiler: { 
    executable: path.join('./compiler', compilerExecutable),
    include: [
      './compiler/include',
      './thirdparty/reapi/addons/amxmodx/scripting/include'
    ]
  },
  input: {
    scripts: './src/scripts',
    include: './src/include',
    assets: './assets'
  },
  output: {
    plugins: './dist/reapi/addons/amxmodx/plugins',
    scripts: './dist/reapi/addons/amxmodx/scripting',
    include: './dist/reapi/addons/amxmodx/scripting/include',
    assets: './dist/reapi'
  },
  rules: {
    flatCompilation: true
  }
}
