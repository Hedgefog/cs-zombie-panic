### Zombie Panic Mod for Counter-Strike 1.6
__Version:__ 1.2.0

### Download latest:
- [Releases](../../releases)

### Requirements
- Amx Mod X 1.9.0+
- RegameDLL + ReAPI
- Metamod-R or Metamod-P (for windows)

### Deployment
- Clone repository.
- Extract compiler executable and includes to _"compiler"_ folder of project.
- Extract ReAPI module to _"thirdparty/reapi"_ folder of project (example: _"thirdparty/reapi/addons"_).
- Install dependencies `npm i`

#### Customize builder
Use `config.user.js` file (Generated automatically on dependencies install)

#### Build project

```bash
npm run build
```

#### Watch project

```bash
npm run watch
```

#### Create bundle

```bash
npm run pack
```
