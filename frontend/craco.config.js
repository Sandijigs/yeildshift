// CRACO configuration to fix openapi-fetch import issue
module.exports = {
  webpack: {
    configure: (webpackConfig) => {
      // Fix for MetaMask SDK analytics openapi-fetch issue
      webpackConfig.resolve.alias = {
        ...webpackConfig.resolve.alias,
        'openapi-fetch': require.resolve('openapi-fetch'),
      };

      // Force webpack to rebuild without cache
      webpackConfig.cache = false;

      return webpackConfig;
    },
  },
};