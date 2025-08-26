import { writable } from 'svelte/store';

export const availableFeatures = writable([]);

export function isFeatureEnabled(featureName) {
  let features;
  availableFeatures.subscribe(value => {
    features = value;
  })();
  
  return features.includes(featureName);
}

export function setAvailableFeatures(features) {
  availableFeatures.set(features || []);
}
