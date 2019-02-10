import std.stdio;
import std.file;
import std.array;
import std.string;
import std.regex;
import std.conv;
import std.math;
import std.algorithm;
import std.range;
import core.stdc.stdlib : exit;
import std.typecons;

auto a = ["Hello"];
auto b = test();
pure auto test()
{
  return null;
}
class TextFile
{
  File file;
  string[] line_array = [];
  string filename;

  this()
  {}

  this(string filename)
  {
    this.filename = filename;
    load();
  }

  auto load(string fname = "")
  {
    //Set a new filename
    if (fname != "")
    {
      filename = fname;
    }
    line_array = readText(filename).splitLines();
  }

  auto save(string fname = "")
  {
    //Set a new filename
    if (fname != "")
    {
      filename = fname;
    }
    with (File(filename, "w"))
    {
      scope(exit) close();

      foreach (line; line_array)
      {
        writeln(line);
      }
    }
  }

  //We should be able to use apply on any string array
  auto apply(string input)
  {
    auto parsed = input.matchFirst(regex(`(?:^(-?[0-9]+)(?:,(-?[0-9]+))?)?(?:[\s]*([^\s]+))?(?:[\s]*(.*))?`));
    int start;
    if (parsed[1] != "")
    {
      start = parsed[1].to!int;
    }
    else
    {
      start = 0;
    }
    start = clamp(wrap_neg(start, line_array.length.to!int), 0, line_array.length-1);
    int end;
    if (parsed[2] != "")
    {
      end = parsed[2].to!int;
    }
    else if (parsed[1] != "")
    {
      end = start;
    }
    else
    {
      end = (line_array.length).to!int;
    }
    end = clamp(wrap_neg(end.to!int, line_array.length.to!int), 0, line_array.length-1);

    auto command_string = parsed[3];
    auto command_arguments = parsed[4];

    auto edit_range = iota(0,0,0);

    if (line_array.length > 0)
    {
      if (end > start)
      {
        edit_range = iota(start, end+1, 1);
      }
      else if (end < start)
      {
        swap(start, end);
        edit_range = iota(end, start-1, -1);
      }
      else
      {
        edit_range = iota(start, end+1, 1);
      }
    }
    writeln(edit_range);

    switch (command_string)
    {
      case "":
      {
        break;
      }

      case "print":
      {
        foreach (i; edit_range)
        {
          writeln(line_array[i]);
        }
        break;
      }

      case "filter":
      {
        auto parsed_rx_string = command_arguments.matchFirst(regex(`/([\S]*)/([a-z]*)`));
        auto regex_options = parsed_rx_string[2].replaceAll(regex("[^gimsx]"), "");
        auto rx = regex(parsed_rx_string[1], regex_options);

        foreach (i; edit_range)
        {
          if (!line_array[i].matchAll(rx).empty())
          {
            writeln(line_array[i]);
          }
        }
        break;
      }

      case "save":
      {
        save(command_arguments);
        break;
      }

      case "load":
      {
        load(command_arguments);
        break;
      }

      case "replace":
      {
        auto parsed_rx_string = command_arguments.matchFirst(regex(`/([\S]*)/([\S]*)/([a-z]*)`));
        auto regex_options = parsed_rx_string[3].replaceAll(regex("[^gimsx]"), "");
        auto rx = regex(parsed_rx_string[1], regex_options);

        foreach (i;edit_range)
        {
          line_array[i] = line_array[i].replaceAll(rx, parsed_rx_string[2]);
        }
        break;
      }

      case "delete":
      {
        line_array = line_array.remove(tuple(start, end+1));
        break;
      }

      case "append":
      {
        int lines_to_append;
        try
        {
          lines_to_append = command_arguments.to!int;
        }
        catch (ConvException e)
        {
          writeln("! Specify the number of lines to append");
          break;
        }

        //If negative line count we want to prepend instead
        auto adjustment = lines_to_append > 0 ? 1 : 0;

        foreach (i; iota(0, lines_to_append.abs()))
        {
          line_array.insertInPlace(min(end+i+adjustment, line_array.length), readln().chomp());
        }
        break;
      }

      case "insert":
      {
        foreach (i; edit_range)
        {
          line_array[i] = readln().chomp();
        }
        break;
      }

      case "quit":
      {
        exit(0);
        break;
      }

      default:
      {
        writeln("! That's not a command");
        break;
      }
    }
  }

  auto print()
  {
    write(join(line_array,"\n"));
  }
}

int wrap_neg(int i, int j){
  if (i >= 0)
  {
    return i;
  }
  else if (j != 0)
  {
    return j+i%j+1;
  }
  else
  {
    return 0;
  }
}

void main()
{
  auto a = new TextFile();
  while (true) {
    write("[| ");
		a.apply(readln());
	}
}
