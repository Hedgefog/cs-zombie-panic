### Zombie Panic Mod for Counter-Strike 1.6
__Version:__ 0.9.5

### Download latest:
- [Releases](./releases)

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
