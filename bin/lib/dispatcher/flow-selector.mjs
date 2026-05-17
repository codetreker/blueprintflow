export function selectFlow(packManifest, wo) {
  const routing = packManifest.routing ?? {};
  const aliases = packManifest.state_aliases ?? {};
  const canonicalState = aliases[wo.current_state] ?? wo.current_state;
  const key = `${wo.schema},${canonicalState}`;
  return routing[key] ?? null;
}
