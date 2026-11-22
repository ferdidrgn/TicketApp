// Pure readers shared by purchase, team and admin views. Metadata is never a row.
const META = new Set([
  'seatIds', 'seatsId', 'closedSeatIds', 'closedSeatsId', '_id',
  '_createdAt', '_updatedAt', 'createdAt', 'updatedAt', 'createdBy',
  'updatedBy', 'schemaVersion', 'seatCount', 'stageId', 'stageName', 'address',
]);

export function seatPlanRows(data) {
  if (!data) return [];
  const flat = data.seatIds ?? data.seatsId;
  const source = Array.isArray(flat) ? [[null, flat]] : Object.entries(data);
  const seen = new Set();
  return source.filter(([key, value]) => !META.has(key) && Array.isArray(value))
    .map(([key, values]) => [key, values.filter((id) => {
      if (typeof id !== 'string' || !id || seen.has(id)) return false;
      seen.add(id);
      return true;
    })]);
}

export function closedSeatIds(data) {
  const ids = data?.closedSeatIds ?? data?.closedSeatsId;
  return Array.isArray(ids) ? ids.filter((id) => typeof id === 'string' && id) : [];
}
