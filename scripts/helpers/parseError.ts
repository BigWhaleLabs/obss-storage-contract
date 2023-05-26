export default function parseError(error: unknown) {
  error instanceof Error ? error.message : error
}
