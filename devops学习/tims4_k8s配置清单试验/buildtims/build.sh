mkdir /root/.m2
cp settings.xml /root/.m2/
mvn install:install-file -Dfile=ojdbc6.jar -DgroupId=com.oracle -DartifactId=ojdbc6 -Dversion=11.2.0.4.0 -Dpackaging=jar
cd src
mvn clean package -Dmaven.test.skip=true
