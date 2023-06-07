export default function (error: unknown) {
  error instanceof Error ? error.message : error
}
