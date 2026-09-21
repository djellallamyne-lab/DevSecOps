@ECHO OFF
@REM Gradle startup script for Windows
SET DIRNAME=%~dp0
IF "%DIRNAME%" == "" SET DIRNAME=.
SET APP_BASE_NAME=%~n0
SET APP_HOME=%DIRNAME%

SET DEFAULT_JVM_OPTS="-Xmx64m" "-Xms64m"

IF DEFINED JAVA_HOME (
  SET JAVA_EXE=%JAVA_HOME%/bin/java.exe
) ELSE (
  SET JAVA_EXE=java.exe
)

SET CLASSPATH=%APP_HOME%\gradle\wrapper\gradle-wrapper.jar

"%JAVA_EXE%" %DEFAULT_JVM_OPTS% %JAVA_OPTS% %GRADLE_OPTS% -classpath "%CLASSPATH%" org.gradle.wrapper.GradleWrapperMain %*
