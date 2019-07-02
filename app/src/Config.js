const Package = require('../package.json');

module.exports = {
    app: {
        name: Package.name,
        env: JSON.stringify(process.env),
        version: Package.version
    },
    cite: 'Век живи - век учись'
};
