enum LogLevel {
  verbose(0, 'V', 'VERBOSE'),
  debug(1, 'D', 'DEBUG'),
  info(2, 'I', 'INFO'),
  warning(3, 'W', 'WARNING'),
  error(4, 'E', 'ERROR'),
  fatal(5, 'F', 'FATAL');

  const LogLevel(this.priority, this.shortName, this.name);

  final int priority;
  final String shortName;
  final String name;

  bool operator >=(LogLevel other) => priority >= other.priority;
  bool operator <=(LogLevel other) => priority <= other.priority;
  bool operator >(LogLevel other) => priority > other.priority;
  bool operator <(LogLevel other) => priority < other.priority;
}
