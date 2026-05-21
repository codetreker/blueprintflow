export function computeAcSignoff({ acList, reviewResults, roleReg }) {
  const perAc = [];
  const flipped = [];
  const missing = [];
  for (const ac of acList) {
    const providers = (roleReg.byCapability.get(ac.capability) || []).map(r => r.id);
    if (providers.length === 0) {
      perAc.push({ id: ac.id, status: "missing", reviewers: [], providers });
      missing.push(`${ac.id}: missing ${ac.capability} (no role provides it)`);
      continue;
    }
    const signedBy = [];
    for (const r of reviewResults) {
      if (providers.includes(r.role) && r.parsed.acceptedIds.includes(ac.id)) {
        signedBy.push(r.role);
      }
    }
    if (signedBy.length > 0) {
      perAc.push({ id: ac.id, status: "signed", reviewers: signedBy, providers });
      if (!ac.checked) flipped.push(ac.id);
    } else {
      perAc.push({ id: ac.id, status: "missing", reviewers: [], providers });
      missing.push(`${ac.id}: missing ${ac.capability} (no provider signed; providers=${providers.join(", ")})`);
    }
  }
  return { perAc, flipped, missing };
}
