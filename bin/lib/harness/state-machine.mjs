export const transitions = {
  bf: {
    Draft:        ["Accepted"],
    Accepted:     ["Implementing"],
    Implementing: ["Completed"],
    Completed:    [],
  },
  taskSpec: {
    Draft:     ["Ready"],
    Ready:     ["Tasking"],
    Tasking:   ["Completed"],
    Completed: [],
  },
};

export function canTransition(kind, from, to) {
  const table = transitions[kind];
  if (!table) return false;
  const allowed = table[from];
  return Array.isArray(allowed) && allowed.includes(to);
}

export function assertTransition(kind, from, to) {
  if (!canTransition(kind, from, to)) {
    throw new Error(`illegal state transition: ${kind} ${from}->${to}`);
  }
}
