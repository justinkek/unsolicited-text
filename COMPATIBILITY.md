# Product compatibility

(audience: humans)

Supported means the rules are printed and drift is caught. Partial means some of
that is missing, and the What works section of the folder linked in the row says
what. Where no folder is linked, nothing installs there yet.

## Anthropic

| Product     | Surface     | Harness execution environment | Installation                                                   | Support                                                             |
| ----------- | ----------- | ----------------------------- | -------------------------------------------------------------- | ------------------------------------------------------------------- |
| Claude Chat | Web GUI     | Hosted                        | [distributions/claude](distributions/claude) | Partial |
|             | Desktop GUI | Hosted                        | (see above)                                                    | Partial |
|             | Mobile GUI  | Hosted                        | (see above)                                                    | Partial |
| Cowork      | Web GUI     | Hosted                        | [distributions/claude](distributions/claude) | Not verified |
|             | Desktop GUI | Hosted                        | (see above)                                                    | Supported |
|             | Mobile GUI  | Hosted                        | (see above)                                                    | Not verified |
|             | Desktop GUI | Local                         | (see above)                                                    | Not verified |
| Claude Code | Web GUI     | Hosted                        | [distributions/claude-code-cloud](distributions/claude-code-cloud)         | Supported |
|             | Desktop GUI | Hosted                        | (see above)                                                    | Supported |
|             | Mobile GUI  | Hosted                        | (see above)                                                    | Supported |
|             | Desktop GUI | Local                         | [distributions/claude](distributions/claude)   | Supported |
|             | CLI         | Local                         | (see above)                                                    | Supported |

## OpenAI

| Product      | Surface       | Harness execution environment | Installation                                      | Support                                                                                                                                                                                                                                                                |
| ------------ | ------------- | ----------------------------- | ------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ChatGPT Chat | Web GUI       | Hosted                        |                                                   | Partial |
|              | Desktop GUI   | Hosted                        |                                                   | Partial |
|              | Mobile GUI    | Hosted                        | Install the plugin from another supported surface | Partial |
| ChatGPT Work | Web GUI       | Hosted                        |                                                   | Not supported |
|              | Desktop GUI   | Local                         |                                                   | Not verified |
|              | Desktop GUI   | Hosted                        |                                                   | Not supported |
|              | Mobile GUI    | Hosted                        | Install the plugin from another supported surface | Not supported |
| Codex        | Web GUI       | Hosted                        |                                                   | Not supported |
|              | Desktop GUI   | Local                         | [distributions/codex](distributions/codex)              | Supported |
|              | Desktop GUI   | Hosted                        |                                                   | Not supported |
|              | CLI           | Local                         | [distributions/codex](distributions/codex)              | Supported |
|              | IDE extension | Local                         |                                                   | Not supported |

## ZCode

| Product | Surface     | Harness execution environment | Installation                                                 | Support                                                                                                                                                                                                         |
| ------- | ----------- | ----------------------------- | ------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| ZCode   | Desktop GUI | Local                         | [distributions/claude](distributions/claude) | Supported |

## Pi

| Product | Surface | Harness execution environment | Installation                   | Support                                                                                                                                                                                                                                                                                               |
| ------- | ------- | ----------------------------- | ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Pi      | CLI     | Local                         | [distributions/pi](distributions/pi) | Partial |
