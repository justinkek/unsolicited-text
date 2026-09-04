<p align="center">
  <img src="logo/logo.png" width="440" alt="unsolicited-text">
</p>

<h1 align="center">consent is important</h1>


## 1. Features

### 1.1. one thread at a time

<table>
<tr>
<td align="center"><b>Before</b></td>
<td align="center"><b>After</b></td>
</tr>
<tr>
<td><img src="demo/reply-before.gif" alt="Seventeen lines of prose with three questions asked inside them"></td>
<td><img src="demo/reply-after.gif" alt="Six lines, then a queue holding a question, an uncertainty and a call taken"></td>
</tr>
</table>

Responses are encouraged to keep to max. 8 lines, and everything else gets added to the queue. 

The queue holds five kinds of item: a question, something unconfirmed, a call taken alone to keep moving, a way a defect could have been caught sooner / prevented, and anything you didn't reply to. 

You can then deal with them one at a time when you feel necessary.

### 1.2. say less, see more

<table>
<tr>
<td align="center"><b>Before</b></td>
<td align="center"><b>After</b></td>
</tr>
<tr>
<td><img src="demo/table-before.gif" alt="Four harnesses compared in four parallel sentences"></td>
<td><img src="demo/table-after.gif" alt="The same four compared in a table"></td>
</tr>
</table>

A picture paints a thousand words.

### 1.3. simple english

<table>
<tr>
<td align="center"><b>Before</b></td>
<td align="center"><b>After</b></td>
</tr>
<tr>
<td><img src="demo/plain-before.gif" alt="An answer given in metaphors and specification names"></td>
<td><img src="demo/plain-after.gif" alt="The same answer in plain words"></td>
</tr>
</table>

ELI5

### 1.4. single sentence confirmations

<table>
<tr>
<td align="center"><b>Before</b></td>
<td align="center"><b>After</b></td>
</tr>
<tr>
<td><img src="demo/directive-before.gif" alt="A finished task reported as a twelve line write-up"></td>
<td><img src="demo/directive-after.gif" alt="The same task reported in one line"></td>
</tr>
</table>

I don't need to hear your life story after asking you to do something.

## 2. How it works

| File                              | When it runs  | What it does                                       | Tokens                                   |
| --------------------------------- | ------------- | -------------------------------------------------- | ---------------------------------------- |
| `hooks/load-agents-md.sh`         | session start | prints `AGENTS.md` into the session                | ~2,400                                   |
| `hooks/remind-response-length.sh` | every prompt  | restates the shortest-form rule                    | ~50                                      |
| `hooks/replay-stop-notes.sh`      | every prompt  | prints the note the last turn recorded             | ~70, and only when there is one          |
| `hooks/note-long-reply.sh`        | turn end      | records a note when the reply ran over the ceiling | none, it prints nothing into the session |

(Estimated at four characters to a token)

## 3. Settings

Every harness reads the same file. Write one `key = value` a line into `~/.unsolicited-text/config`:

```text
PROSE_LINE_CEILING = 12
```

| Setting                | Default                           | What it holds                                                    |
| ---------------------- | --------------------------------- | ---------------------------------------------------------------- |
| `PROSE_LINE_CEILING`   | `8`                               | non-blank lines of prose a reply may run to before a note is kept |
| `STOP_NOTE_DIRECTORY`  | `~/.unsolicited-text/state/notes` | where a turn leaves the note the next turn reads                  |

Nothing is written there for you, and an absent file means the defaults above. A variable of the same name in the environment wins over the file, so a single session can be run against another ceiling without editing anything. `UNSOLICITED_TEXT_HOME` moves the file and the state under it together.

Anything the hooks write for themselves lives under `~/.unsolicited-text/state/`. Deleting that directory loses the note a turn was holding and nothing else; your settings sit beside it, not inside it.

## 4. Install

Copy/paste into your CLI prompt:

```text
Install the unsolicited-text plugin from https://github.com/justinkek/unsolicited-text, refer to the repo's INSTALL.md for instructions.
```

Or 🔗 [check the installation instructions](INSTALL.md).

## 5. Tests

    tests/run-tests

Each pair is typed out from `demo/<name>.prompt`, `demo/<name>-before.txt` and
`demo/<name>-after.txt`. Edit any of them and record again:

    brew install vhs
    demo/record

## 6. Docs
The logo is drawn in `logo/logo.svg` and rendered by `logo/render`.

They are typed in Commit Mono at the palette in `demo/record`. Without that face installed the recording falls back to another one, and `demo/record` says so before it starts.
